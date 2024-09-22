//
//  Calendar+Ext.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/22.
//

import Foundation

extension Calendar {
    func isDateInYesterdayOrEarlier(_ date: Date) -> Bool {
        return self.compare(date, to: Date(), toGranularity: .day) == .orderedAscending
    }
}
