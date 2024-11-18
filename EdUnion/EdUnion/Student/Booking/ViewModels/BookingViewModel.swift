//
//  BookingViewModel.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/10/18.
//

import Foundation
import FirebaseCore
import SwiftUI

class BookingViewModel: ObservableObject {
    @Published var selectedDate: String?
    @Published var selectedTimes: [String] = []
    @Published var bookedSlots: [String] = []
    @Published var showingAlert = false
    @Published var alertMessage = ""
    
    private let teacherID: String
    private let userID = UserSession.shared.unwrappedUserID
    private let timeSlots: [AvailableTimeSlot]
    let selectedTimeSlots: [String: String]
    
    init(teacherID: String, timeSlots: [AvailableTimeSlot], selectedTimeSlots: [String: String]) {
        self.teacherID = teacherID
        self.timeSlots = timeSlots
        self.selectedTimeSlots = selectedTimeSlots
    }
    
    var availableDates: [String] {
        let today = Date()
        let calendar = Calendar.current
        
        return Array(selectedTimeSlots.keys).filter { dateString in
            if let date = TimeService.sharedDateFormatter.date(from: dateString) {
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
        guard TimeService.sharedTimeFormatter.date(from: timeSlot) != nil else { return }
        
        var updatedSelection = selectedTimes
        
        if let index = updatedSelection.firstIndex(of: timeSlot) {
            updatedSelection.remove(at: index)
        } else {
            updatedSelection.append(timeSlot)
            updatedSelection.sort()
        }
        
        if isSelectionContinuous(updatedSelection) {
            selectedTimes = updatedSelection
        } else {
            alertUser(with: "只能選擇連續的時間段。")
        }
    }
    
    private func isSelectionContinuous(_ times: [String]) -> Bool {
        guard times.count > 1 else { return true }
        
        let sortedTimes = times.sorted(by: TimeService.compareTimes)
        
        for i in 0..<(sortedTimes.count - 1) {
            guard let first = TimeService.sharedTimeFormatter.date(from: sortedTimes[i]),
                  let second = TimeService.sharedTimeFormatter.date(from: sortedTimes[i + 1]) else { return false }
            
            let difference = Calendar.current.dateComponents([.minute], from: first, to: second).minute
            if difference != 30 { return false }
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
        guard let date = TimeService.sharedDateFormatter.date(from: dateString) else { return false }
        return Calendar.current.isDateInToday(date)
    }
    
    func isTimeSlotInPast(_ timeSlot: String, comparedTo currentDate: Date) -> Bool {
        guard let slotTime = TimeService.sharedTimeFormatter.date(from: timeSlot),
              let selectedDate = selectedDate,
              let fullDate = TimeService.dateFrom(dateString: selectedDate, timeString: timeSlot) else {
            return false
        }
        return fullDate < currentDate
    }
    
    func submitBooking() {
        guard let date = selectedDate, !selectedTimes.isEmpty else {
            alertUser(with: "請選擇日期和至少一個時間段。")
            return
        }
        
        let bookingRef = UserFirebaseService.shared.db.collection(Constants.appointmentsCollection).document()
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
        AppointmentFirebaseService.shared.fetchAllAppointments(forTeacherID: teacherID) { [weak self] result in
            switch result {
            case .success(let appointments):
                self?.bookedSlots = appointments
                    .filter { $0.date == date }
                    .flatMap { $0.times }
            case .failure(let error):
                print("Error fetching appointments: \(error)")
                self?.bookedSlots = []
            }
        }
    }
    
    private func alertUser(with message: String) {
        alertMessage = message
        showingAlert = true
    }
    
    var isSubmitButtonEnabled: Bool {
            selectedDate != nil && !selectedTimes.isEmpty
        }

    func backgroundColor(for timeSlot: TimeSlot) -> Color {
            if timeSlot.isBooked {
                return .gray
            } else if isSelected(timeSlot: timeSlot.time) {
                return .mainOrange
            } else {
                return .myMessageCell
            }
        }

        func foregroundColor(for timeSlot: TimeSlot) -> Color {
            if timeSlot.isBooked || isSelected(timeSlot: timeSlot.time) {
                return .white
            } else {
                return Color(UIColor.systemBackground)
            }
        }
}
