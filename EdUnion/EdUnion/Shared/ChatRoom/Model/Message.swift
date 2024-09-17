//
//  Message.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/11.
//

import Foundation

struct Message {
    let ID: String?
    let type: Int
    var content: String
    let senderID: String
    let isSentByCurrentUser: Bool
    let isSeen: Bool
    let timestamp: Date

    init(ID: String? = nil, type: Int, content: String, senderID: String, isSentByCurrentUser: Bool, isSeen: Bool, timestamp: Date) {
        self.ID = ID
        self.type = type
        self.content = content
        self.senderID = senderID
        self.isSentByCurrentUser = isSentByCurrentUser
        self.isSeen = isSeen
        self.timestamp = timestamp
    }
}
