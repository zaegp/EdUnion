//
//  ChatRoom.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/17.
//

import Foundation
import FirebaseFirestore

struct ChatRoom: Decodable {
    let id: String
    let participants: [String]
    let messages: [Message]?
    let lastMessage: String?
    let lastMessageTimestamp: Timestamp?

    enum CodingKeys: String, CodingKey {
        case id
        case participants
        case lastMessage
        case lastMessageTimestamp
        case messages
    }
}

//    init?(id: String, data: [String: Any]) {
//        guard let participants = data["participants"] as? [String],
//              let lastMessage = data["lastMessage"] as? String?,
//              let lastMessageTimestamp = (data["lastMessageTimestamp"] as? Timestamp)?.dateValue() else {
//            return nil
//        }
//        
//        self.id = id
//        self.participants = participants
//        self.lastMessage = lastMessage
//        self.lastMessageTimestamp = lastMessageTimestamp
//        self.messages = [] 
//    }
