//
//  Appointment.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/15.
//

import Foundation

enum AppointmentStatus: String {
    case pending
    case confirmed
    case completed
    case canceling
    case canceled
    case rejected
}

struct Appointment: Identifiable, Codable {
    var id: String?
    let date: String
    var status: String
    let studentID: String
    let teacherID: String
    let times: [String]
    let timestamp: Date
    
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
