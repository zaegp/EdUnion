//
//  TimeSlot.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/11/7.
//

import Foundation

struct TimeSlot: Identifiable {
    let id = UUID()
    let time: String
    let isBooked: Bool
}
