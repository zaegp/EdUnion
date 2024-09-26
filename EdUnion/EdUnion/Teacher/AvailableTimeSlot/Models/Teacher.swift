//
//  Teacher.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/14.
//

import Foundation

struct Teacher: UserProtocol, Codable {
    var id: String
    var resume : [String]
//    var lastLogin: Date
    var name: String
    var photoURL: String?
//    var uid: String
    let selectedTimeSlots: [String : String]?
    let timeSlots: [AvailableTimeSlot]
    var totalCourses: Int
    var studentsNotes: [String : String]?
}
