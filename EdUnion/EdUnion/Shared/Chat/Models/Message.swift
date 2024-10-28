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
    var isSeen: Bool
    let timestamp: Timestamp
    
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        
        guard let type = data["type"] as? Int,
              let content = data["content"] as? String,
              let senderID = data["senderID"] as? String,
              let isSeen = data["isSeen"] as? Bool,
              let timestamp = data["timestamp"] as? Timestamp else {
            return nil
        }
        
        self.init(ID: document.documentID, type: type, content: content, senderID: senderID, isSeen: isSeen, timestamp: timestamp)
    }
    
    init(ID: String?, type: Int, content: String, senderID: String, isSeen: Bool, timestamp: Timestamp) {
        self.ID = ID
        self.type = type
        self.content = content
        self.senderID = senderID
        self.isSeen = isSeen
        self.timestamp = timestamp
    }
}
