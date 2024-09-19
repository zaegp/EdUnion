//
//  ChatViewModel.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/11.
//

import UIKit
import FirebaseFirestore

class ChatViewModel {
    
    private var messages: [Message] = []
    private let chatRoomID: String
    private let currentUserID: String
    private var pendingImages: [String: UIImage] = [:]
    
    var onMessagesUpdated: (() -> Void)?
    
    init(chatRoomID: String, currentUserID: String) {
        self.chatRoomID = teacherID + "_" + studentID
        self.currentUserID = teacherID
        
        fetchMessages()
    }
    
    func numberOfMessages() -> Int {
        return messages.count
    }
    
    func message(at index: Int) -> Message {
        return messages[index]
    }
    
    func getPendingImage(for messageId: String) -> UIImage? {
        return pendingImages[messageId]
    }
    
    func sendMessage(_ text: String) {
        let messageId = UUID().uuidString
        let messageData: [String: Any] = [
            "ID": messageId,
            "senderID": currentUserID,
            "type": 0, 
            "content": text,
            "timestamp": FieldValue.serverTimestamp(),
            "isSeen": false
        ]
        
        UserFirebaseService.shared.sendMessage(chatRoomID: chatRoomID, messageData: messageData) { error in
            if let error = error {
                print("Error sending message: \(error)")
            } else {
                print("Message sent successfully")
            }
        }
    }
    
    func sendPhotoMessage(_ image: UIImage) {
        let messageId = UUID().uuidString
        let documentRef = UserFirebaseService.shared.db.collection("chats").document(chatRoomID).collection("messages").document(messageId)
        
        let messageData: [String: Any] = [
            "ID": messageId,
            "senderID": currentUserID,
            "type": 1,
            "content": "",
            "timestamp": FieldValue.serverTimestamp(),
            "isSeen": false
        ]
        
        documentRef.setData(messageData) { error in
            if let error = error {
                print("Error sending photo message: \(error)")
                return
            }
            
            self.pendingImages[messageId] = image
            self.onMessagesUpdated?()
            self.uploadPhoto(image, for: messageId)
        }
    }
    
    private func uploadPhoto(_ image: UIImage, for messageId: String) {
        UserFirebaseService.shared.uploadPhoto(image: image, messageId: messageId) { [weak self] result in
            switch result {
            case .success(let url):
                print("Successfully uploaded image. URL: \(url)")
                
                // 更新消息的 Firestore URL
                UserFirebaseService.shared.updateMessage(chatRoomID: self?.chatRoomID ?? "", messageId: messageId, updatedData: ["content": url]) { error in
                    if let error = error {
                        print("Error updating message with imageURL in Firestore: \(error.localizedDescription)")
                    } else {
                        print("Message updated with imageURL in Firestore successfully")
                        self?.pendingImages.removeValue(forKey: messageId)
                    }
                }
            case .failure(let error):
                print("Error uploading image: \(error.localizedDescription)")
            }
        }
    }
    
    func sendAudioMessage(_ audioData: Data) {
        let audioId = UUID().uuidString
        
        UserFirebaseService.shared.uploadAudio(audioData: audioData, audioId: audioId) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let url):
                let messageData: [String: Any] = [
                    "senderID": self.currentUserID,
                    "type": 2,  // 假設 '2' 代表音訊消息
                    "content": url,
                    "timestamp": FieldValue.serverTimestamp(),
                    "isSeen": false
                ]
                
                UserFirebaseService.shared.sendMessage(chatRoomID: self.chatRoomID, messageData: messageData) { error in
                    if let error = error {
                        print("Error sending audio message: \(error.localizedDescription)")
                    } else {
                        print("Audio message sent successfully")
                    }
                }
                
            case .failure(let error):
                print("Error uploading audio: \(error.localizedDescription)")
            }
        }
    }
    
    func fetchMessages() {
        UserFirebaseService.shared.fetchMessages(chatRoomID: chatRoomID, currentUserID: currentUserID) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let newMessages):
                newMessages.forEach { newMessage in
                    if !self.messages.contains(where: { $0.ID == newMessage.ID }) {
                        self.messages.append(newMessage)
                    }
                }
                
                self.onMessagesUpdated?()
                
            case .failure(let error):
                print("Error fetching messages: \(error.localizedDescription)")
            }
        }
    }
}
