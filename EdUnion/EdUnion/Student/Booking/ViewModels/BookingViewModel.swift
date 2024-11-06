//
//  BookingViewModel.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/10/18.
//

import Foundation
import FirebaseCore

//class BookingViewModel: ObservableObject {
//    @Published var selectedDate: String?
//    @Published var selectedTimes: [String] = []
//    @Published var bookedSlots: [String] = []
//
//    let teacherID: String
//    let timeSlots: [AvailableTimeSlot]
//    let selectedTimeSlots: [String: String]
//    
//    init(teacherID: String, userID: String, timeSlots: [AvailableTimeSlot], selectedTimeSlots: [String: String]) {
//            self.teacherID = teacherID
//            self.timeSlots = timeSlots
//            self.selectedTimeSlots = selectedTimeSlots
//        }
//    
//    var availableTimeSlotsForSelectedDate: [String] {
//        guard let selectedDate = selectedDate else { return [] }
//        let allSlots = timeSlots.filter { $0.colorHex == selectedTimeSlots[selectedDate] }
//            .flatMap { generateTimeSlots(from: $0.timeRanges, bookedSlots: bookedSlots) }
//        
//        if TimeService.isToday(selectedDate) {
//            let now = Date()
//            return allSlots.filter { !TimeService.isTimeSlotInPast($0, comparedTo: now) }
//        } else {
//            return allSlots
//        }
//    }
//
//    func generateTimeSlots(from timeRanges: [String], bookedSlots: [String]) -> [String] {
//        var timeSlots: [String] = []
//        
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "HH:mm"
//        
//        for range in timeRanges {
//            let times = range.split(separator: "-").map { $0.trimmingCharacters(in: .whitespaces) }
//            
//            if let startTime = dateFormatter.date(from: String(times[0])),
//               let endTime = dateFormatter.date(from: String(times[1])) {
//                var currentTime = startTime
//                
//                while currentTime < endTime {
//                    let timeString = dateFormatter.string(from: currentTime)
//                    timeSlots.append(timeString)
//                    
//                    if let newTime = Calendar.current.date(byAdding: .minute, value: 30, to: currentTime) {
//                        currentTime = newTime
//                    } else {
//                        break
//                    }
//                }
//            }
//        }
//        return timeSlots
//    }
//    
//    func toggleSelection(of timeSlot: String) {
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "HH:mm"
//        
//        guard dateFormatter.date(from: timeSlot) != nil else { return }
//        
//        if let index = selectedTimes.firstIndex(of: timeSlot) {
//            var newSelection = selectedTimes
//            newSelection.remove(at: index)
//            
//            if isSelectionContinuous(newSelection) {
//                selectedTimes = newSelection
//            }
//        } else {
//            var newSelection = selectedTimes + [timeSlot]
//            newSelection.sort()
//            
//            if isSelectionContinuous(newSelection) {
//                selectedTimes.append(timeSlot)
//            }
//        }
//    }
//    
//    func isSelectionContinuous(_ times: [String]) -> Bool {
//        guard times.count > 1 else { return true }
//        
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "HH:mm"
//        
//        let sortedTimes = times.sorted {
//            dateFormatter.date(from: $0)! < dateFormatter.date(from: $1)!
//        }
//        
//        for i in 0..<(sortedTimes.count - 1) {
//            guard let firstTime = dateFormatter.date(from: sortedTimes[i]),
//                  let secondTime = dateFormatter.date(from: sortedTimes[i + 1]) else {
//                return false
//            }
//            
//            let difference = Calendar.current.dateComponents([.minute], from: firstTime, to: secondTime).minute
//            if difference != 30 {
//                return false
//            }
//        }
//        
//        return true
//    }
//    
//    func getBookedSlots(for date: String, completion: @escaping ([String]) -> Void) {
//        AppointmentFirebaseService.shared.fetchAllAppointments(forTeacherID: teacherID) { result in
//            switch result {
//            case .success(let appointments):
//                let filteredAppointments = appointments.filter { appointment in
//                    appointment.date == date
//                }
//                
//                let bookedSlots = filteredAppointments.flatMap { $0.times }
//                completion(bookedSlots)
//                
//            case .failure(let error):
//                print("Error fetching appointments: \(error)")
//                completion([])
//            }
//        }
//    }
//}

struct TimeSlot: Identifiable {
    let id = UUID()
    let time: String
    let isBooked: Bool
}

class BookingViewModel: ObservableObject {
    @Published var selectedDate: String?
    @Published var selectedTimes: [String] = []
    @Published var bookedSlots: [String] = []
    @Published var showingAlert = false
    @Published var alertMessage = ""

    let teacherID: String
    let userID = UserSession.shared.unwrappedUserID
    let timeSlots: [AvailableTimeSlot]
    let selectedTimeSlots: [String: String]

    init(teacherID: String, timeSlots: [AvailableTimeSlot], selectedTimeSlots: [String: String]) {
        self.teacherID = teacherID
        self.timeSlots = timeSlots
        self.selectedTimeSlots = selectedTimeSlots
    }

    var availableDates: [String] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let today = Date()
        let calendar = Calendar.current
        
        return Array(selectedTimeSlots.keys).filter { dateString in
            if let date = dateFormatter.date(from: dateString) {
                return calendar.isDate(date, inSameDayAs: today) || date > today
            }
            return false
        }.sorted()
    }

    var availableTimeSlotsForSelectedDate: [TimeSlot] {
        guard let selectedDate = selectedDate else { return [] }
        let allSlots = timeSlots.filter { $0.colorHex == selectedTimeSlots[selectedDate] }
            .flatMap { generateTimeSlots(from: $0.timeRanges) }
        
        if isToday(selectedDate) {
            let now = Date()
            return allSlots.filter { !isTimeSlotInPast($0.time, comparedTo: now) }
        } else {
            return allSlots
        }
    }

    func isSelected(timeSlot: String) -> Bool {
        return selectedTimes.contains(timeSlot)
    }

    func isBooked(timeSlot: String) -> Bool {
        return bookedSlots.contains(timeSlot)
    }

    func toggleSelection(of timeSlot: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        guard dateFormatter.date(from: timeSlot) != nil else { return }
        
        if let index = selectedTimes.firstIndex(of: timeSlot) {
            var newSelection = selectedTimes
            newSelection.remove(at: index)
            
            if isSelectionContinuous(newSelection) {
                selectedTimes = newSelection
            } else {
                alertMessage = "只能選擇連續的時間段。"
                showingAlert = true
            }
        } else {
            var newSelection = selectedTimes + [timeSlot]
            newSelection.sort()
            
            if isSelectionContinuous(newSelection) {
                selectedTimes = newSelection
            } else {
                alertMessage = "只能選擇連續的時間段。"
                showingAlert = true
            }
        }
    }

    func isSelectionContinuous(_ times: [String]) -> Bool {
        guard times.count > 1 else { return true }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        let sortedTimes = times.sorted {
            dateFormatter.date(from: $0)! < dateFormatter.date(from: $1)!
        }
        
        for i in 0..<(sortedTimes.count - 1) {
            guard let firstTime = dateFormatter.date(from: sortedTimes[i]),
                  let secondTime = dateFormatter.date(from: sortedTimes[i + 1]) else {
                return false
            }
            
            let difference = Calendar.current.dateComponents([.minute], from: firstTime, to: secondTime).minute
            if difference != 30 {
                return false
            }
        }
        
        return true
    }

    func generateTimeSlots(from timeRanges: [String]) -> [TimeSlot] {
        var timeSlots: [TimeSlot] = []
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        for range in timeRanges {
            let times = range.split(separator: "-").map { $0.trimmingCharacters(in: .whitespaces) }
            
            if let startTime = dateFormatter.date(from: String(times[0])),
               let endTime = dateFormatter.date(from: String(times[1])) {
                var currentTime = startTime
                
                while currentTime < endTime {
                    let timeString = dateFormatter.string(from: currentTime)
                    let isBooked = bookedSlots.contains(timeString)
                    let timeSlot = TimeSlot(time: timeString, isBooked: isBooked)
                    timeSlots.append(timeSlot)
                    
                    if let newTime = Calendar.current.date(byAdding: .minute, value: 30, to: currentTime) {
                        currentTime = newTime
                    } else {
                        break
                    }
                }
            }
        }
        return timeSlots
    }

    func isToday(_ dateString: String) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let selectedDate = dateFormatter.date(from: dateString) else { return false }
        let calendar = Calendar.current
        return calendar.isDateInToday(selectedDate)
    }

    func isTimeSlotInPast(_ timeSlot: String, comparedTo currentDate: Date) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        guard let slotTime = dateFormatter.date(from: timeSlot),
              let selectedDate = selectedDate,
              let fullDate = DateFormatter.dateFrom(dateString: selectedDate, timeString: timeSlot) else {
            return false
        }
        
        return fullDate < currentDate
    }

    func submitBooking() {
        guard let date = selectedDate, !selectedTimes.isEmpty else {
            alertMessage = "請選擇日期和至少一個時間段。"
            showingAlert = true
            return
        }
        
        let bookingRef = UserFirebaseService.shared.db.collection("appointments").document()
        let documentID = bookingRef.documentID
        
        let bookingData: [String: Any] = [
            "id": documentID,
            "studentID": userID,
            "teacherID": teacherID,
            "date": date,
            "times": selectedTimes,
            "status": "pending",
            "timestamp": Timestamp(date: Date())
        ]
        
        bookingRef.setData(bookingData) { error in
            if let error = error {
                self.alertMessage = "預定失敗：\(error.localizedDescription)"
                self.showingAlert = true
            } else {
                self.alertMessage = "預定成功！"
                self.showingAlert = true
                self.selectedDate = nil
                self.selectedTimes = []
            }
        }
        
        UserFirebaseService.shared.updateStudentList(teacherID: teacherID, listName: "usedList", add: true) { error in
            if let error = error {
                print("更新 usedList 失败: \(error)")
            } else {
                print("成功更新 usedList")
            }
        }
    }

    func getBookedSlots(for date: String) {
        AppointmentFirebaseService.shared.fetchAllAppointments(forTeacherID: teacherID) { result in
            switch result {
            case .success(let appointments):
                let filteredAppointments = appointments.filter { appointment in
                    appointment.date == date
                }
                
                let bookedSlots = filteredAppointments.flatMap { $0.times }
                DispatchQueue.main.async {
                    self.bookedSlots = bookedSlots
                }
                
            case .failure(let error):
                print("Error fetching appointments: \(error)")
                DispatchQueue.main.async {
                    self.bookedSlots = []
                }
            }
        }
    }
}

extension DateFormatter {
    static func dateFrom(dateString: String, timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.date(from: "\(dateString) \(timeString)")
    }
}
