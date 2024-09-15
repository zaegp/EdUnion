//
//  AvailableTimeSlot.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/14.
//

import Foundation

struct AvailableTimeSlot: Codable, Equatable {
    var colorHex: String
    var timeRanges: [String]
    
    func toDictionary() -> [String: Any] {
        return [
            "colorHex": colorHex,
            "timeRanges": timeRanges
        ]
    }
    
    static func fromDictionary(_ dict: [String: Any]) -> AvailableTimeSlot? {
        if let colorHex = dict["colorHex"] as? String,
           let timeRanges = dict["timeRanges"] as? [String] {
            return AvailableTimeSlot(colorHex: colorHex, timeRanges: timeRanges)
        }
        return nil
    }
}
