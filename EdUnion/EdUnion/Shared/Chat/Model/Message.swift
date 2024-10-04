//
//  Message.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/11.
//

import Foundation
import FirebaseFirestore

struct Message: Decodable {
    let ID: String?
    let type: Int
    var content: String
    let senderID: String
    let isSeen: Bool
    let timestamp: Timestamp

    // Firestore 自動解碼時使用的鍵對應
    enum CodingKeys: String, CodingKey {
        case ID
        case type
        case content
        case senderID
        case isSeen
        case timestamp
    }
    
    init?(document: QueryDocumentSnapshot) {
            let data = document.data()

            // 手動提取和轉換字段
            guard let type = data["type"] as? Int,
                  let content = data["content"] as? String,
                  let senderID = data["senderID"] as? String,
                  let isSeen = data["isSeen"] as? Bool,
                  let timestamp = data["timestamp"] as? Timestamp else {
                return nil
            }

            self.ID = document.documentID
            self.type = type
            self.content = content
            self.senderID = senderID
            self.isSeen = isSeen
            self.timestamp = timestamp
        }
}

//struct Message {
//    let ID: String?
//    let type: Int
//    var content: String
//    let senderID: String
//    let isSentByCurrentUser: Bool
//    let isSeen: Bool
//    let timestamp: Date
//
//    init(ID: String? = nil, type: Int, content: String, senderID: String, isSentByCurrentUser: Bool, isSeen: Bool, timestamp: Date) {
//        self.ID = ID
//        self.type = type
//        self.content = content
//        self.senderID = senderID
//        self.isSentByCurrentUser = isSentByCurrentUser
//        self.isSeen = isSeen
//        self.timestamp = timestamp
//    }
//}
