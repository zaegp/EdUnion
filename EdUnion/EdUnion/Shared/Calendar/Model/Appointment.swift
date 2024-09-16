//
//  Appointment.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/15.
//

import Foundation

struct Appointment: Identifiable, Codable {
    var id: String?
    let date: String        // "yyyy-MM-dd"
    let status: String      // e.g., "pending"
    let studentID: String   // e.g., "002"
    let teacherID: String   // e.g., "001"
    let times: [String]     // e.g., ["06:30", "07:00", "07:30"]
    let timestamp: Date     // Firestore Timestamp
    
    enum CodingKeys: String, CodingKey {
        case id
        case date
        case status
        case studentID
        case teacherID
        case times
        case timestamp
    }
}
