//
//  Date+Ext.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/17.
//

import Foundation

extension Date {
    func formattedChatDate() -> String {
        return TimeService.formattedChatDate(from: self)
    }

    func isToday() -> Bool {
        return Calendar.current.isDateInToday(self)
    }
}
