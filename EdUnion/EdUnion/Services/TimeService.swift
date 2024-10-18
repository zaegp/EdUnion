//
//  TimeService.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/20.
//

import Foundation

class TimeService {
    
    static let sharedDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
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
        inputFormatter.dateFormat = "yyyy-MM-dd"  
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "MMM\nd" 
        
        if let date = inputFormatter.date(from: dateString) {
            return outputFormatter.string(from: date)
        }
        return dateString
    }
    
    static func sortCourses(by activities: [Appointment], ascending: Bool = false) -> [Appointment] {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm"

            return activities.sorted { (a, b) -> Bool in
                guard let timeAFull = a.times.first,
                      let timeBFull = b.times.first,
                      let startTimeAString = timeAFull.split(separator: "-").first?.trimmingCharacters(in: .whitespaces),
                      let startTimeBString = timeBFull.split(separator: "-").first?.trimmingCharacters(in: .whitespaces),
                      let dateA = dateFormatter.date(from: startTimeAString),
                      let dateB = dateFormatter.date(from: startTimeBString) else {
                    return false
                }
                return ascending ? dateA > dateB : dateA < dateB
            }
        }
}
