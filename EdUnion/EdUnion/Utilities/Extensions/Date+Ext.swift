//
//  Date+Ext.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/17.
//

import Foundation

extension Date {
    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

extension Date {
    func formattedChatDate() -> String {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        
        if calendar.isDateInToday(self) {
            dateFormatter.dateFormat = "HH:mm"
        } else if calendar.isDate(self, equalTo: Date(), toGranularity: .year) {
            dateFormatter.dateFormat = "MM/dd"
        } else {
            dateFormatter.dateFormat = "yyyy/MM/dd"
        }
        
        return dateFormatter.string(from: self)
    }
}
