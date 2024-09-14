//
//  Message.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/11.
//

import Foundation

struct Message {
    let id: String?
    let text: String?
    let imageURL: String?
    let audioURL: String?
    let senderID: String
    let isSentByCurrentUser: Bool
    let isSeen: Bool
    let timestamp: Date

    init(id: String? = nil, text: String? = nil, imageURL: String? = nil, audioURL: String? = nil, senderID: String, isSentByCurrentUser: Bool, isSeen: Bool, timestamp: Date) {
        self.id = id
        self.text = text
        self.imageURL = imageURL
        self.audioURL = audioURL
        self.senderID = senderID
        self.isSentByCurrentUser = isSentByCurrentUser
        self.isSeen = isSeen
        self.timestamp = timestamp
    }
}
