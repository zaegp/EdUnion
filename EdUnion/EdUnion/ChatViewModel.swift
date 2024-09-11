//
//  ChatViewModel.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/11.
//

import Foundation
import FirebaseFirestore

class ChatViewModel {
    
    private var messages: [Message] = []
    private let chatRoomID: String
    private let currentUserID: String
    private let db = Firestore.firestore()
    
    // 綁定數據更新
    var onMessagesUpdated: (() -> Void)?
    
    init(chatRoomID: String, currentUserID: String) {
        self.chatRoomID = chatRoomID
        self.currentUserID = currentUserID
        
        // 初始化時監聽 Firebase 中的訊息變更
        fetchMessages()
    }
    
    // 獲取訊息數量
    func numberOfMessages() -> Int {
        return messages.count
    }
    
    // 根據索引獲取訊息
    func message(at index: Int) -> Message {
        return messages[index]
    }
    
    // 發送訊息
    func sendMessage(_ text: String) {
        // 立即將消息添加到本地數據陣列
        let newMessage = Message(
            id: nil,
            text: text,
            senderID: currentUserID,
            isSentByCurrentUser: true,
            isSeen: false,
            timestamp: Date()
        )
        
        // 先在本地更新訊息
        self.messages.append(newMessage)
        self.onMessagesUpdated?()  // 立即通知界面更新
        
        // 同時發送到 Firebase
        let messageData: [String: Any] = [
            "senderID": currentUserID,
            "text": text,
            "timestamp": FieldValue.serverTimestamp(),
            "isSeen": false
        ]
        
        db.collection("chats").document(chatRoomID).collection("messages").addDocument(data: messageData) { error in
            if let error = error {
                print("Error sending message: \(error)")
            } else {
                print("Message sent successfully")
            }
        }
    }
    
    // 從 Firebase 中實時獲取聊天記錄
    private func fetchMessages() {
        db.collection("chats").document(chatRoomID).collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] (snapshot, error) in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching messages: \(error)")
                    return
                }
                
                self.messages = snapshot?.documents.compactMap { document in
                    let data = document.data()
                    return Message(
                        id: document.documentID,
                        text: data["text"] as? String ?? "",
                        senderID: data["senderID"] as? String ?? "",
                        isSentByCurrentUser: (data["senderID"] as? String == self.currentUserID),
                        isSeen: data["isSeen"] as? Bool ?? false,
                        timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                    )
                } ?? []
                
                // 通知視圖更新
                self.onMessagesUpdated?()
            }
    }
}