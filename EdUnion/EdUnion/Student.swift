//
//  Student.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/23.
//

import Foundation

struct Student: UserProtocol, Codable {
    var followList: [String]  // 這裡用來儲存追蹤的老師ID
    var usedList: [String]    // 這裡用來儲存已預約的老師ID
    var name: String          // 學生名字
    var photoURL: String?      // 學生的圖片URL
}
