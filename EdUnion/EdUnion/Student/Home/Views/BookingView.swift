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
                                bookedSlots.removeAll()  // 清除之前的預定時段
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
                    
                    if slotsForDate.isEmpty {
                        VStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.gray)
                            Text("該日期暫無可用的時間段")
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
                                            .animation(isBooked(timeSlot: timeSlot) ? .easeInOut : nil)  // 只對已被預約的時間段應用動畫
                                    }
                                    .disabled(isBooked(timeSlot: timeSlot))
                                }
                            }
                            .padding()
                        }
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
        
        // 將時間轉換為 Date 類型
        guard let selectedTime = dateFormatter.date(from: timeSlot) else { return }
        
        // 檢查是否為取消選取的情況
        if let index = selectedTimes.firstIndex(of: timeSlot) {
            // 如果是取消選取，直接移除選擇
            selectedTimes.remove(at: index)
            return
        }
        
        // 檢查添加新的時間段是否連續
        var allSelectedTimes = selectedTimes + [timeSlot]
        allSelectedTimes.sort()
        
        for i in 0..<(allSelectedTimes.count - 1) {
            guard let firstTime = dateFormatter.date(from: allSelectedTimes[i]),
                  let secondTime = dateFormatter.date(from: allSelectedTimes[i + 1]) else {
                return
            }
            
            // 如果兩個時間之間的間隔不是 30 分鐘，則顯示警告訊息並返回
            if Calendar.current.dateComponents([.minute], from: firstTime, to: secondTime).minute != 30 {
                alertMessage = "只能選擇連續的時間段。"
                showingAlert = true
                return
            }
        }
        
        // 如果是新增選取，通過連續性檢查後才添加
        selectedTimes.append(timeSlot)
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
