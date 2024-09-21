//
//  TimeService.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/20.
//

import Foundation

class TimeService {
    
    static func convertCourseTimeToDisplay(from times: [String]) -> String {
        guard let firstTime = times.first else { return "" }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        if let startTime = dateFormatter.date(from: firstTime) {
            if times.count == 1 {
                if let endTime = Calendar.current.date(byAdding: .minute, value: 30, to: startTime) {
                    return "\(firstTime) - \(dateFormatter.string(from: endTime))"
                }
            } else if let lastTime = times.last, let endTime = dateFormatter.date(from: lastTime) {
                if let extendedEndTime = Calendar.current.date(byAdding: .minute, value: 30, to: endTime) {
                    return "\(firstTime) - \(dateFormatter.string(from: extendedEndTime))"
                }
            }
        }
        
        return ""
    }
    
    static func covertToEnMonth (_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"  // 原始日期格式
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "MMM\nd"  // 轉換成 "Sep\n21" 的格式
        
        if let date = inputFormatter.date(from: dateString) {
            return outputFormatter.string(from: date)
        }
        return dateString
    }
}
