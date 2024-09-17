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
