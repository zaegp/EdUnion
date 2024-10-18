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
    let chatRoomID: String
    let userID = UserSession.shared.currentUserID
    private var pendingImages: [String: UIImage] = [:]
    private var participants: [String] = []
    private var listener: ListenerRegistration?
    var onMessagesUpdated: (() -> Void)?

    //    var otherParticipantID: String
    
    init(chatRoomID: String) {
        self.chatRoomID = chatRoomID
        self.participants = chatRoomID.split(separator: "_").map { String($0) }
        //            self.otherParticipantID = participants.first { $0 != userID }
        
        defer {
            fetchMessages()
        }
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
            "senderID": userID,
            "type": 0,
            "content": text,
            "timestamp": FieldValue.serverTimestamp(),
            "isSeen": false
        ]
        
        let chatRoomRef = UserFirebaseService.shared.db.collection("chats").document(chatRoomID)
        
        chatRoomRef.collection("messages").document(messageId).setData(messageData) { error in
            if let error = error {
                print("Error sending message: \(error)")
            } else {
                print("Message sent successfully")
                
                chatRoomRef.setData([
                    "id": self.chatRoomID,
                    "participants": self.participants,
                    "lastMessage": text,
                    "lastMessageTimestamp": FieldValue.serverTimestamp()
                ], merge: true)
            }
        }
    }
    
    func addVideoCallMessage() {
        let messageId = UUID().uuidString
        let messageData: [String: Any] = [
            "ID": messageId,
            "senderID": userID,
            "content": "已離開課堂",
            "timestamp": FieldValue.serverTimestamp(),
            "type": 2,
            "isSeen": false
        ]
        
        let chatRoomRef = UserFirebaseService.shared.db.collection("chats").document(chatRoomID)
        let messagesRef = chatRoomRef.collection("messages").document(messageId)
        
        messagesRef.setData(messageData) { error in
            if let error = error {
                print("Error sending message: \(error)")
            } else {
                print("Message sent successfully")
                
                chatRoomRef.setData([
                    "id": self.chatRoomID,
                    "participants": self.participants,
                    "lastMessage": "已離開課堂",
                    "lastMessageTimestamp": FieldValue.serverTimestamp()
                ], merge: true)
            }
        }
    }
    
    func sendPhotoMessage(_ image: UIImage) {
        let messageId = UUID().uuidString
        let chatRoomRef = UserFirebaseService.shared.db.collection("chats").document(chatRoomID)
        
        let messageData: [String: Any] = [
            "ID": messageId,
            "senderID": userID,
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
            
            chatRoomRef.setData([
                "id": self.chatRoomID,
                "participants": self.participants,
                "lastMessage": "圖片",
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
    
    func markMessageAsSeen(_ message: Message) {
            guard let messageID = message.ID else { return }
            let chatRoomRef = Firestore.firestore().collection("chatRooms").document(chatRoomID)
            let messageRef = chatRoomRef.collection("messages").document(messageID)
            
            messageRef.updateData(["isSeen": true]) { error in
                if let error = error {
                    print("Failed to update isSeen: \(error)")
                } else {
                    print("Message \(messageID) marked as seen.")
                }
            }
        }
    
    func updateMessageIsSeen(at index: Int) {
            messages[index].isSeen = true
            onMessagesUpdated?()
        }
    
    func fetchMessages() {
        listener = UserFirebaseService.shared.db.collection("chats").document(chatRoomID).collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { [weak self] (snapshot, error) in
                guard let self = self else { return }
                if let error = error {
                    print("Error fetching messages: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No documents")
                    return
                }
                
                var newMessages: [Message] = []
                
                for document in documents {
                    if let message = Message(document: document) {
                        newMessages.append(message)
                    }
                }
                
                self.messages = newMessages
                
                self.onMessagesUpdated?()
            }
    }
    
}
