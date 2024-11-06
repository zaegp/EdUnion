//
//  BookingView.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/15.
//

import SwiftUI
import FirebaseCore

struct BookingView: View {
    let teacherID: String
    let selectedTimeSlots: [String: String]
    let timeSlots: [AvailableTimeSlot]
    var availableTimeSlotsForSelectedDate: [String] {
        guard let selectedDate = selectedDate else { return [] }
        let allSlots = timeSlots.filter { $0.colorHex == selectedTimeSlots[selectedDate] }
            .flatMap { generateTimeSlots(from: $0.timeRanges, bookedSlots: bookedSlots) }
        
        if isToday(selectedDate) {
            let now = Date()
            return allSlots.filter { timeSlot in
                !isTimeSlotInPast(timeSlot, comparedTo: now)
            }
        } else {
            return allSlots
        }
    }
    
    @State private var selectedDate: String?
    @State private var selectedTimes: [String] = []
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var bookedSlots: [String] = []
    let userID = UserSession.shared.currentUserID ?? ""
    
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
    
    var body: some View {
        VStack {
            if availableDates.isEmpty {
                VStack {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.gray)
                    Text("暫無可預約的日期")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .padding()
                Spacer()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(availableDates, id: \.self) { date in
                            Button(action: {
                                selectedDate = date
                                selectedTimes = []
                                bookedSlots.removeAll() 
                                getBookedSlots(for: selectedDate ?? "") { slots in
                                    bookedSlots = slots
                                    _ = generateTimeSlots(from: timeSlots.flatMap { $0.timeRanges }, bookedSlots: bookedSlots)
                                }
                            }) {
                                VStack {
                                    Text(formattedDate(date))
                                        .font(.headline)
                                        .foregroundColor(Color(UIColor.systemBackground))
                                    Text(formattedWeekday(date))
                                        .font(.subheadline)
                                        .foregroundColor(Color(UIColor.systemBackground))
                                }
                                .padding()
                                .background(selectedDate == date ? Color.mainOrange : Color.myMessageCell)
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding()
                }
                
                if let selectedDate = selectedDate, let colorHex = selectedTimeSlots[selectedDate] {
                    let slotsForDate = timeSlots.filter { $0.colorHex == colorHex }
                    
                    if availableTimeSlotsForSelectedDate.isEmpty {
                        Spacer()
                        noAvailableTimeSlotsView()
                    } else {
                        availableTimeSlotsView()
                    }
                } else {
                    Text("請選擇日期")
                        .font(.headline)
                        .padding()
                    Spacer()
                }
            }
            
            Spacer()
            
            Button(action: submitBooking) {
                Text("確定預約")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background((selectedDate != nil && !selectedTimes.isEmpty) ? Color.mainOrange : Color.gray)
                    .cornerRadius(10)
                    .padding([.horizontal, .bottom])
            }
            .disabled(selectedDate == nil || selectedTimes.isEmpty)
        }
        .frame(maxHeight: .infinity)
        .background(Color.myBackground)
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("通知"), message: Text(alertMessage), dismissButton: .default(Text("確定")))
        }
    }
    
    private func noAvailableTimeSlotsView() -> some View {
        return VStack {
            Image(systemName: "clock.arrow.circlepath")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.gray)
            Text("該日期暫無可用的時間段")
                .font(.headline)
                .foregroundColor(.gray)
        }
    }

    private func availableTimeSlotsView() -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3), spacing: 20) {
                ForEach(availableTimeSlotsForSelectedDate, id: \.self) { timeSlot in
                    timeSlotButton(timeSlot)
                }
            }
            .padding()
        }
    }

    private func timeSlotButton(_ timeSlot: String) -> some View {
        Button(action: {
            toggleSelection(of: timeSlot)
        }) {
            Text(timeSlot)
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .background(buttonBackgroundColor(for: timeSlot))
                .foregroundColor(buttonForegroundColor(for: timeSlot))
                .cornerRadius(10)
        }
        .animation(.easeInOut, value: isBooked(timeSlot: timeSlot))
        .disabled(isBooked(timeSlot: timeSlot))
    }
        
    func formattedDate(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "MM月dd日"
        if let date = inputFormatter.date(from: dateString) {
            return outputFormatter.string(from: date)
        }
        return dateString
    }
    
    func formattedWeekday(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        let outputFormatter = DateFormatter()
        outputFormatter.locale = Locale(identifier: "zh_CN")
        outputFormatter.dateFormat = "EEEE"
        if let date = inputFormatter.date(from: dateString) {
            let weekday = outputFormatter.string(from: date)
            return weekday
        }
        return ""
    }
    
    func isSelected(timeSlot: String) -> Bool {
        return selectedTimes.contains(timeSlot)
    }
    
    func isBooked(timeSlot: String) -> Bool {
        return bookedSlots.contains(timeSlot)
    }
    
    func buttonBackgroundColor(for timeSlot: String) -> Color {
        if isBooked(timeSlot: timeSlot) {
            return Color.gray
        } else if isSelected(timeSlot: timeSlot) {
            return Color.mainOrange
        } else {
            return Color.myMessageCell
        }
    }
    
    func buttonForegroundColor(for timeSlot: String) -> Color {
        if isBooked(timeSlot: timeSlot) {
            return Color.white
        } else if isSelected(timeSlot: timeSlot) {
            return Color.white
        } else {
            return Color(UIColor.systemBackground)
        }
    }
    
    func generateTimeSlots(from timeRanges: [String], bookedSlots: [String]) -> [String] {
        var timeSlots: [String] = []
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        for range in timeRanges {
            let times = range.split(separator: "-").map { $0.trimmingCharacters(in: .whitespaces) }
            
            if let startTime = dateFormatter.date(from: String(times[0])),
               let endTime = dateFormatter.date(from: String(times[1])) {
                var currentTime = startTime
                
                while currentTime < endTime {
                    let timeString = dateFormatter.string(from: currentTime)
                    timeSlots.append(timeString)
                    
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
    
    func toggleSelection(of timeSlot: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        guard let selectedTime = dateFormatter.date(from: timeSlot) else { return }
        
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
                selectedTimes.append(timeSlot)
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
    
    func isToday(_ dateString: String) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let selectedDate = dateFormatter.date(from: dateString)
        let calendar = Calendar.current
        return calendar.isDateInToday(selectedDate ?? Date())
    }

    func isTimeSlotInPast(_ timeSlot: String, comparedTo currentDate: Date) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        guard let slotTime = dateFormatter.date(from: timeSlot) else { return false }
        
        let calendar = Calendar.current
        let slotDate = calendar.date(bySettingHour: calendar.component(.hour, from: slotTime),
                                    minute: calendar.component(.minute, from: slotTime),
                                    second: 0, of: currentDate) ?? currentDate
        
        return slotDate < currentDate
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
                alertMessage = "預定失敗：\(error.localizedDescription)"
                showingAlert = true
            } else {
                alertMessage = "預定成功！"
                showingAlert = true
                selectedDate = nil
                selectedTimes = []
            }
        }
        
        UserFirebaseService.shared.updateStudentList(studentID: userID, teacherID: teacherID, listName: "usedList", add: true) { error in
            if let error = error {
                print("更新 usedList 失败: \(error)")
            } else {
                print("成功更新 usedList")
            }
        }
    }
    
    func getBookedSlots(for date: String, completion: @escaping ([String]) -> Void) {
        AppointmentFirebaseService.shared.fetchAllAppointments(forTeacherID: teacherID) { result in
            switch result {
            case .success(let appointments):
                let filteredAppointments = appointments.filter { appointment in
                    appointment.date == date
                }
                
                let bookedSlots = filteredAppointments.flatMap { $0.times }
                completion(bookedSlots)
                
            case .failure(let error):
                print("Error fetching appointments: \(error)")
                completion([])
            }
        }
    }
}
