//
//  Message.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/11.
//

import Foundation

struct Message {
    let id: String?
    let text: String
    let senderID: String
    let isSentByCurrentUser: Bool
    let isSeen: Bool
    let timestamp: Date
}
