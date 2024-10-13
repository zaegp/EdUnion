//
//  Message.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/11.
//

import Foundation
import FirebaseFirestore

//struct Message: Decodable {
//    let ID: String?
//    let type: Int
//    var content: String
//    let senderID: String
//    var isSeen: Bool
//    let timestamp: Timestamp
//
//    // Firestore 自動解碼時使用的鍵對應
//    enum CodingKeys: String, CodingKey {
//        case ID
//        case type
//        case content
//        case senderID
//        case isSeen
//        case timestamp
//    }
//    
//    init?(document: QueryDocumentSnapshot) {
//            let data = document.data()
//
//            // 手動提取和轉換字段
//            guard let type = data["type"] as? Int,
//                  let content = data["content"] as? String,
//                  let senderID = data["senderID"] as? String,
//                  let isSeen = data["isSeen"] as? Bool,
//                  let timestamp = data["timestamp"] as? Timestamp else {
//                return nil
//            }
//
//            self.ID = document.documentID
//            self.type = type
//            self.content = content
//            self.senderID = senderID
//            self.isSeen = isSeen
//            self.timestamp = timestamp
//        }
//}

struct Message: Decodable {
    let ID: String?
    let type: Int
    var content: String
    let senderID: String
    var isSeen: Bool
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
    
    // 用於從 Firestore 文檔初始化
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

    // 新增這個初始化器來支持手動創建 Message
    init(ID: String?, type: Int, content: String, senderID: String, isSeen: Bool, timestamp: Timestamp) {
        self.ID = ID
        self.type = type
        self.content = content
        self.senderID = senderID
        self.isSeen = isSeen
        self.timestamp = timestamp
    }
}
