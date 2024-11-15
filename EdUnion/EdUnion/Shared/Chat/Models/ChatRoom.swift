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
    let messages: [Message]? = nil
    let lastMessage: String?
    let lastMessageTimestamp: Timestamp?

    enum CodingKeys: String, CodingKey {
        case id
        case participants
        case lastMessage
        case lastMessageTimestamp
        case messages
    }
    
    init?(document: DocumentSnapshot) {
            guard
                let data = document.data(),
                let participants = data["participants"] as? [String]
            else { return nil }
            
            self.id = document.documentID
            self.participants = participants
            self.lastMessage = data["lastMessage"] as? String
            self.lastMessageTimestamp = data["lastMessageTimestamp"] as? Timestamp
        }
}
