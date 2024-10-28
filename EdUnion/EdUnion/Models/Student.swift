//
//  Student.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/23.
//

import Foundation

struct Student: UserProtocol, Codable {
    var id: String = ""
    var userID: String
    var followList: [String]
    var usedList: [String]
    var fullName: String
    var photoURL: String?
    
    private enum CodingKeys: String, CodingKey {
        case userID, followList, usedList, fullName, photoURL
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.userID = try container.decode(String.self, forKey: .userID)
        self.followList = try container.decodeIfPresent([String].self, forKey: .followList) ?? []
        self.usedList = try container.decodeIfPresent([String].self, forKey: .usedList) ?? []
        self.fullName = try container.decode(String.self, forKey: .fullName)
        self.photoURL = try container.decodeIfPresent(String.self, forKey: .photoURL)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userID, forKey: .userID)
        try container.encode(followList, forKey: .followList)
        try container.encode(usedList, forKey: .usedList)
        try container.encode(fullName, forKey: .fullName)
        try container.encode(photoURL, forKey: .photoURL)
    }
}
