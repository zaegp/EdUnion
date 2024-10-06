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
                // 空状态：没有可用日期
                VStack {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.gray)
                    Text("暂无可预订的日期")
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
                                
                                getBookedSlots(for: selectedDate ?? "") { slots in
                                    bookedSlots = slots
                                    _ = generateTimeSlots(from: timeSlots.flatMap { $0.timeRanges }, bookedSlots: bookedSlots)
                                }
                            }) {
                                VStack {
                                    Text(formattedDate(date))
                                        .font(.headline)
                                        .foregroundColor(selectedDate == date ? .white : .primary)
                                    Text(formattedWeekday(date))
                                        .font(.subheadline)
                                        .foregroundColor(selectedDate == date ? .white : .secondary)
                                }
                                .padding()
                                .background(selectedDate == date ? Color.accentColor : Color.gray.opacity(0.2))
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding()
                }
                
                if let selectedDate = selectedDate, let colorHex = selectedTimeSlots[selectedDate] {
                    let slotsForDate = timeSlots.filter { $0.colorHex == colorHex }
                    
                    if slotsForDate.isEmpty {
                        // 空状态：该日期没有可用时间段
                        VStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.gray)
                            Text("该日期暂无可用的时间段")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        Spacer()
                    } else {
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3), spacing: 20) {
                                ForEach(slotsForDate.flatMap { generateTimeSlots(from: $0.timeRanges, bookedSlots: bookedSlots) }, id: \.self) { timeSlot in
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
                                    .disabled(isBooked(timeSlot: timeSlot))
                                }
                            }
                            .padding()
                        }
                    }
                } else {
                    Text("请选择日期")
                        .font(.headline)
                        .padding()
                    Spacer()
                }
            }
            
            Spacer()
            
            Button(action: submitBooking) {
                Text("提交预订")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background((selectedDate != nil && !selectedTimes.isEmpty) ? Color.accentColor : Color.gray)
                    .cornerRadius(10)
                    .padding([.horizontal, .bottom])
            }
            .disabled(selectedDate == nil || selectedTimes.isEmpty)
        }
        .frame(maxHeight: .infinity)
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("通知"), message: Text(alertMessage), dismissButton: .default(Text("确定")))
        }
    }
    
    // 辅助方法
    
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
            return Color.gray.opacity(0.2)
        } else if isSelected(timeSlot: timeSlot) {
            return Color.green
        } else {
            return Color.blue
        }
    }
    
    func buttonForegroundColor(for timeSlot: String) -> Color {
        if isBooked(timeSlot: timeSlot) {
            return Color.gray
        } else {
            return Color.white
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
        if let index = selectedTimes.firstIndex(of: timeSlot) {
            selectedTimes.remove(at: index)
        } else {
            selectedTimes.append(timeSlot)
        }
    }
    
    func submitBooking() {
        guard let date = selectedDate, !selectedTimes.isEmpty else {
            alertMessage = "请选择日期和至少一个时间段。"
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
                alertMessage = "预订失败：\(error.localizedDescription)"
                showingAlert = true
            } else {
                alertMessage = "预订成功！"
                showingAlert = true
                selectedDate = nil
                selectedTimes = []
            }
        }
        
        UserFirebaseService.shared.updateStudentList(studentID: userID, teacherID: teacherID, listName: "usedList") { error in
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
//#Preview {
//    BookingView(selectedTimeSlots: ["2024-09-11": "#FF624F", "2024-09-13": "#FF624F", "2024-09-12": "#000000", "2024-10-10": "#FF624F"], timeSlots: [EdUnion.TimeSlot(colorHex: "#FF624F", timeRanges: ["08:00 - 11:00", "14:00 - 18:00"]), EdUnion.TimeSlot(colorHex: "#000000", timeRanges: ["06:00 - 21:00"])])
//}
