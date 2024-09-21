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
