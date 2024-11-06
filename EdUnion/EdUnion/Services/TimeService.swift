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
    
    static let sharedTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    static let sharedChatRoomFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    static func isTimeSlotInPast(_ timeSlot: String, comparedTo currentDate: Date) -> Bool {
        guard let slotTime = sharedTimeFormatter.date(from: timeSlot) else { return false }
        
        let calendar = Calendar.current
        let slotDate = calendar.date(bySettingHour: calendar.component(.hour, from: slotTime),
                                     minute: calendar.component(.minute, from: slotTime),
                                     second: 0, of: currentDate) ?? currentDate
        
        return slotDate < currentDate
    }
    
    static func isToday(_ dateString: String) -> Bool {
        guard let selectedDate = sharedDateFormatter.date(from: dateString) else { return false }
        let calendar = Calendar.current
        return calendar.isDateInToday(selectedDate)
    }
    
    static func formattedMonthAndYear(for date: Date, isWeekView: Bool) -> String {
        let formatter = DateFormatter()
        if isWeekView {
            let calendar = Calendar.current
            guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)),
                  let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) else {
                return ""
            }
            formatter.dateFormat = "MMM d"
            let startString = formatter.string(from: startOfWeek)
            let endString = formatter.string(from: endOfWeek)
            return "\(startString) - \(endString)"
        } else {
            formatter.dateFormat = "yyyy MMM"
            return formatter.string(from: date)
        }
    }
    
    static func convertCourseTimeToDisplay(from times: [String]) -> String {
        guard let firstTime = times.first else { return "" }
        
        let startTime = sharedTimeFormatter.date(from: firstTime)
        
        if let startTime = startTime {
            if times.count == 1 {
                if let endTime = Calendar.current.date(byAdding: .minute, value: 30, to: startTime) {
                    return "\(firstTime) - \(sharedTimeFormatter.string(from: endTime))"
                }
            } else if let lastTime = times.last, let endTime = sharedTimeFormatter.date(from: lastTime) {
                if let extendedEndTime = Calendar.current.date(byAdding: .minute, value: 30, to: endTime) {
                    return "\(firstTime) - \(sharedTimeFormatter.string(from: extendedEndTime))"
                }
            }
        }
        
        return ""
    }
    
    static func covertToEnMonth(_ dateString: String) -> String {
        guard let date = sharedDateFormatter.date(from: dateString) else {
            return dateString
        }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "MMM\nd"
        return outputFormatter.string(from: date)
    }
    
    static func sortCourses(by activities: [Appointment], ascending: Bool = false) -> [Appointment] {
        return activities.sorted { (a, b) -> Bool in
            guard let timeAFull = a.times.first,
                  let timeBFull = b.times.first,
                  let startTimeAString = timeAFull.split(separator: "-").first?.trimmingCharacters(in: .whitespaces),
                  let startTimeBString = timeBFull.split(separator: "-").first?.trimmingCharacters(in: .whitespaces),
                  let dateA = sharedTimeFormatter.date(from: startTimeAString),
                  let dateB = sharedTimeFormatter.date(from: startTimeBString) else {
                return false
            }
            return ascending ? dateA > dateB : dateA < dateB
        }
    }
    
    static func covertToChatRoomFormat(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            sharedChatRoomFormatter.dateFormat = "HH:mm"
        } else if calendar.isDateInYesterday(date) {
            sharedChatRoomFormatter.dateFormat = "昨天 HH:mm"
        } else {
            sharedChatRoomFormatter.dateFormat = "MM/dd HH:mm"
        }
        
        return sharedChatRoomFormatter.string(from: date)
    }
    
    // 預約頁面
    static func formattedDate(_ dateString: String) -> String {
        let inputFormatter = sharedDateFormatter
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "MM月dd日"
        outputFormatter.timeZone = TimeZone.current
        if let date = inputFormatter.date(from: dateString) {
            return outputFormatter.string(from: date)
        }
        return dateString
    }
    
    static func formattedWeekday(_ dateString: String) -> String {
        let inputFormatter = sharedDateFormatter
        let outputFormatter = DateFormatter()
        outputFormatter.locale = Locale(identifier: "zh_CN")
        outputFormatter.dateFormat = "EEEE"
        outputFormatter.timeZone = TimeZone.current
        if let date = inputFormatter.date(from: dateString) {
            let weekday = outputFormatter.string(from: date)
            return weekday
        }
        return ""
    }
}
