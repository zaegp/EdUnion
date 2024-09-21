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
    let currentUserID: String
    private var pendingImages: [String: UIImage] = [:]
    private var participants: [String] = []
    private let otherParticipantID: String
    
    var onMessagesUpdated: (() -> Void)?
    
    init(chatRoomID: String, currentUserID: String, otherParticipantID: String) {
        self.chatRoomID = chatRoomID
        self.currentUserID = currentUserID
        self.otherParticipantID = otherParticipantID
        
        var currentUserIsOdd = false
        if let userIDInt = Int(currentUserID) {  // 將 String 轉換為 Int
            currentUserIsOdd = userIDInt % 2 != 0  // 判斷是否為奇數
        } else {
            print("currentUserID 轉換失敗: \(currentUserID)")
            currentUserIsOdd = false
        }
        
        if currentUserIsOdd {
            participants = [currentUserID, otherParticipantID]  // 當前用戶是老師
        } else {
            participants = [otherParticipantID, currentUserID]  // 當前用戶是學生
        }
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
        
        let chatRoomRef = UserFirebaseService.shared.db.collection("chats").document(chatRoomID)
        
        // 更新 messages 集合中的數據
        chatRoomRef.collection("messages").document(messageId).setData(messageData) { error in
            if let error = error {
                print("Error sending message: \(error)")
            } else {
                print("Message sent successfully")
                
                // 更新 chatRoom 集合的 participants、lastMessage 和 lastMessageTimestamp
                chatRoomRef.setData([
                    "id": self.chatRoomID,
                    "participants": self.participants,  // 老師和學生ID
                    "lastMessage": text,
                    "lastMessageTimestamp": FieldValue.serverTimestamp()
                ], merge: true)  // 使用 merge 來更新字段，而不會覆蓋現有數據
            }
        }
    }
    
    func sendPhotoMessage(_ image: UIImage) {
        let messageId = UUID().uuidString
        let chatRoomRef = UserFirebaseService.shared.db.collection("chats").document(chatRoomID)
        
        let messageData: [String: Any] = [
            "ID": messageId,
            "senderID": currentUserID,
            "type": 1,
            "content": "",
            "timestamp": FieldValue.serverTimestamp(),
            "isSeen": false
        ]
        
        chatRoomRef.collection("messages").document(messageId).setData(messageData) { error in
            if let error = error {
                print("Error sending photo message: \(error)")
                return
            }
            
            self.pendingImages[messageId] = image
            self.onMessagesUpdated?()
            self.uploadPhoto(image, for: messageId)
            
            // 更新 chatRoom 集合的 participants、lastMessage 和 lastMessageTimestamp
            chatRoomRef.setData([
                "id": self.chatRoomID,
                "participants": self.participants,
                "lastMessage": "圖片",  // 可以用"圖片"或者其他提示
                "lastMessageTimestamp": FieldValue.serverTimestamp()
            ], merge: true)
        }
    }
    
    private func uploadPhoto(_ image: UIImage, for messageId: String) {
        UserFirebaseService.shared.uploadPhoto(image: image, messageId: messageId) { [weak self] url, error in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                return
            }
            
            guard let url = url else {
                print("Failed to retrieve image URL after upload")
                return
            }
            
            print("Successfully uploaded image. URL: \(url)")
            
            UserFirebaseService.shared.updateMessage(chatRoomID: self?.chatRoomID ?? "", messageId: messageId, updatedData: ["content": url]) { error in
                if let error = error {
                    print("Error updating message with imageURL in Firestore: \(error.localizedDescription)")
                } else {
                    print("Message updated with imageURL in Firestore successfully")
                    
                    self?.pendingImages.removeValue(forKey: messageId)
                }
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
                print("Fetched newMessages: \(newMessages)")
                newMessages.forEach { newMessage in
                    // 避免重複添加相同的消息
                    if !self.messages.contains(where: { $0.ID == newMessage.ID }) {
                        self.messages.append(newMessage)
                    }
                }
                
                // 通知 UI 刷新
                self.onMessagesUpdated?()
                
            case .failure(let error):
                print("Error fetching messages: \(error.localizedDescription)")
            }
        }
    }
}
