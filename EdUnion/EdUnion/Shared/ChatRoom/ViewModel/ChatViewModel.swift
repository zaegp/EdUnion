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
            "type": 0, // 0 for text
            "content": text,
            "timestamp": FieldValue.serverTimestamp(),
            "isSeen": false
        ]
        
        FirebaseService.shared.sendMessage(chatRoomID: chatRoomID, messageData: messageData) { error in
            if let error = error {
                print("Error sending message: \(error)")
            } else {
                print("Message sent successfully")
            }
        }
    }
    
    func sendPhotoMessage(_ image: UIImage) {
        let messageId = UUID().uuidString
        let documentRef = FirebaseService.shared.db.collection("chats").document(chatRoomID).collection("messages").document(messageId)
        
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
        FirebaseService.shared.uploadPhoto(image: image, messageId: messageId) { [weak self] url, error in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                return
            }
            
            guard let url = url else {
                print("Failed to retrieve image URL after upload")
                return
            }
            
            print("Successfully uploaded image. URL: \(url)")
            
            // 更新 Firestore 中的圖片 URL
            FirebaseService.shared.updateMessage(chatRoomID: self!.chatRoomID, messageId: messageId, updatedData: ["content": url]) { error in
                if let error = error {
                    print("Error updating message with imageURL in Firestore: \(error.localizedDescription)")
                } else {
                    print("Message updated with imageURL in Firestore successfully")
                    
                    self?.pendingImages.removeValue(forKey: messageId)
                    self?.onMessagesUpdated?()
                }
            }
        }
    }
    
    func sendAudioMessage(_ audioData: Data) {
        let audioId = UUID().uuidString
        
        FirebaseService.shared.uploadAudio(audioData: audioData, audioId: audioId) { [weak self] url, error in
            if let error = error {
                print("Error uploading audio: \(error)")
                return
            }
            
            if let url = url {
                let messageData: [String: Any] = [
                    "senderID": self!.currentUserID,
                    "type": 2,
                    "content": url,
                    "timestamp": FieldValue.serverTimestamp(),
                    "isSeen": false
                ]
                
                FirebaseService.shared.sendMessage(chatRoomID: self!.chatRoomID, messageData: messageData) { error in
                    if let error = error {
                        print("Error sending audio message: \(error)")
                    }
                }
            }
        }
    }
    
    func fetchMessages() {
        FirebaseService.shared.fetchMessages(chatRoomID: chatRoomID, currentUserID: currentUserID) { [weak self] newMessages, error in
            if let error = error {
                print("Error fetching messages: \(error)")
                return
            }
            
            newMessages.forEach { newMessage in
                if !(self?.messages.contains(where: { $0.ID == newMessage.ID }) ?? false) {
                    self?.messages.append(newMessage)
                }
            }
            
            self?.onMessagesUpdated?()
        }
    }
}
