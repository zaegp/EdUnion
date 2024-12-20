//
//  Teacher.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/14.
//

import Foundation

struct Teacher: Equatable, UserProtocol, Codable {
    var id: String = ""
    var userID: String
    var resume: [String]
    var fullName: String
    var photoURL: String?
    let selectedTimeSlots: [String: String]?
    let timeSlots: [AvailableTimeSlot]?
    var totalCourses: Int
    var studentsNotes: [String: String]?
    var email: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userID = try container.decodeIfPresent(String.self, forKey: .userID) ?? ""
        resume = try container.decodeIfPresent([String].self, forKey: .resume) ?? []
        fullName = try container.decodeIfPresent(String.self, forKey: .fullName) ?? ""
        photoURL = try container.decodeIfPresent(String.self, forKey: .photoURL)
        selectedTimeSlots = try container.decodeIfPresent([String: String].self, forKey: .selectedTimeSlots)
        timeSlots = try container.decodeIfPresent([AvailableTimeSlot].self, forKey: .timeSlots)
        totalCourses = try container.decodeIfPresent(Int.self, forKey: .totalCourses) ?? 0
        studentsNotes = try container.decodeIfPresent([String: String].self, forKey: .studentsNotes)
        email = try container.decodeIfPresent(String.self, forKey: .email)
    }
    
    init(
        id: String = "",
        userID: String,
        fullName: String,
        photoURL: String? = nil,
        totalCourses: Int = 0,
        resume: [String] = [],
        selectedTimeSlots: [String: String]? = nil,
        timeSlots: [AvailableTimeSlot]? = nil,
        studentsNotes: [String: String]? = nil,
        email: String? = nil
    ) {
        self.id = id
        self.userID = userID
        self.fullName = fullName
        self.photoURL = photoURL
        self.totalCourses = totalCourses
        self.resume = resume
        self.selectedTimeSlots = selectedTimeSlots
        self.timeSlots = timeSlots
        self.studentsNotes = studentsNotes
        self.email = email
    }
}
