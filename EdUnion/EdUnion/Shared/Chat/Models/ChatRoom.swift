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
