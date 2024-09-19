//
//  BookingView.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/15.
//

import SwiftUI
import FirebaseCore

struct BookingView: View {
    let selectedTimeSlots: [String: String]
    let timeSlots: [AvailableTimeSlot]
    
    @State private var selectedDate: String?
    @State private var selectedTimes: [String] = []  // 存儲為 String 類型
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var bookedSlots: [String] = []  // 用來存放已預約的時段，也為 String
    
    var availableDates: [String] {
        return Array(selectedTimeSlots.keys).sorted()
    }
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHGrid(rows: [GridItem(.flexible())], spacing: 15) {
                        ForEach(availableDates, id: \.self) { date in
                            Button(action: {
                                selectedDate = date
                                selectedTimes = []
                                
                                // 根據選擇的日期加載已預約的時間段
                                getBookedSlots(for: selectedDate ?? "") { slots in
                                    bookedSlots = slots
                                }
                            }) {
                                Text(date)
                                    .padding()
                                    .background(selectedDate == date ? .mainOrange : Color.gray.opacity(0.2))
                                    .foregroundColor(selectedDate == date ? .white : .black)
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding()
                }
                
                if let selectedDate = selectedDate, let colorHex = selectedTimeSlots[selectedDate] {
                    let slotsForDate = timeSlots.filter { $0.colorHex == colorHex }
                    
                    if slotsForDate.isEmpty {
                        Text("無可用時間段")
                            .padding()
                    } else {
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3), spacing: 20) {
                                ForEach(slotsForDate.flatMap { generateTimeSlots(from: $0.timeRanges, bookedSlots: bookedSlots) }, id: \.self) { timeSlot in
                                    Button(action: {
                                        toggleSelection(of: timeSlot) // 點擊按鈕選擇時間
                                    }) {
                                        Text(timeSlot)
                                            .frame(height: 50)
                                            .frame(maxWidth: .infinity)
                                            .background(
                                                isSelected(timeSlot: timeSlot) ? Color.mainOrange : Color.background
                                            )
                                            .foregroundColor(
                                                isSelected(timeSlot: timeSlot) ? .white : .black
                                            )
                                            .cornerRadius(10)
                                    }
                                }
                            }
                            .padding()
                        }
                        
                    }
                } else {
                    Text("請選擇日期")
                        .padding()
                }
                
                Spacer()
                
                Button(action: submitBooking) {
                    Text("提交預約")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background((selectedDate != nil && !selectedTimes.isEmpty) ? Color(UIColor(resource: .mainOrange)) : Color.gray)
                        .cornerRadius(10)
                        .padding([.horizontal, .bottom])
                }
                .disabled(selectedDate == nil || selectedTimes.isEmpty)
            }
            .navigationBarTitle("預約", displayMode: .inline)
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("通知"), message: Text(alertMessage), dismissButton: .default(Text("確定")))
            }
        }
    }
    
    func getBookedSlots(for date: String, completion: @escaping ([String]) -> Void) {
            // 從 Firebase 獲取該老師的所有預約
            AppointmentFirebaseService.shared.fetchAllAppointments(forTeacherID: teacherID) { result in
                switch result {
                case .success(let appointments):
                    // 過濾出符合指定日期的預約
                    let filteredAppointments = appointments.filter { appointment in
                        appointment.date == date  // 比較日期 (已經是 String 格式)
                    }
                    
                    // 提取符合日期的所有已預約時間段，並以字符串返回
                    let bookedSlots = filteredAppointments.flatMap { $0.times }  // 合併所有已預約時間段
                    completion(bookedSlots)
                    
                case .failure(let error):
                    print("Error fetching appointments: \(error)")
                    completion([])  // 如果發生錯誤，返回空數組
                }
            }
        }
    
    func isSelected(timeSlot: String) -> Bool {
        return selectedTimes.contains(timeSlot) // 檢查是否包含這個時間
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
                    // 如果當前時間不在已預約時段中，則加入可選時段
                    if !bookedSlots.contains(timeString) {
                        timeSlots.append(timeString)
                    }
                    
                    // 將時間加 30 分鐘
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
        // 如果已經選擇了這個時間，則取消選擇
        if let index = selectedTimes.firstIndex(of: timeSlot) {
            selectedTimes.remove(at: index)
        } else {
            // 檢查新的時間是否與已選擇的時間段相差30分鐘
            if selectedTimes.isEmpty {
                selectedTimes.append(timeSlot)
            } else {
                let sortedTimes = selectedTimes.sorted()
                if let firstTime = sortedTimes.first,
                   let lastTime = sortedTimes.last,
                   let timePlus30 = addMinutes(to: timeSlot, minutes: 30),
                   let timeMinus30 = subtractMinutes(from: timeSlot, minutes: 30) {
                    
                    if timePlus30 == firstTime || timeMinus30 == lastTime {
                        // 如果新的時間與已選時間段連續，則允許添加
                        selectedTimes.append(timeSlot)
                    } else {
                        // 不連續，顯示錯誤
                        alertMessage = "請選擇連續的時間段（間隔30分鐘）。"
                        showingAlert = true
                    }
                }
            }
        }
    }
    
    func addMinutes(to time: String, minutes: Int) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        if let date = dateFormatter.date(from: time),
           let newTime = Calendar.current.date(byAdding: .minute, value: minutes, to: date) {
            return dateFormatter.string(from: newTime)
        }
        return nil
    }

    func subtractMinutes(from time: String, minutes: Int) -> String? {
        return addMinutes(to: time, minutes: -minutes)
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
            "studentID": studentID,
            "teacherID": teacherID,
            "date": date,
            "times": selectedTimes,  // 這裡是 [String]
            "status": "pending",
            "timestamp": Timestamp(date: Date())
        ]
        
        bookingRef.setData(bookingData) { error in
            if let error = error {
                alertMessage = "預約失敗：\(error.localizedDescription)"
                showingAlert = true
            } else {
                alertMessage = "預約成功！"
                showingAlert = true
                selectedDate = nil
                selectedTimes = []
            }
        }
    }
}

//#Preview {
//    BookingView(selectedTimeSlots: ["2024-09-11": "#FF624F", "2024-09-13": "#FF624F", "2024-09-12": "#000000", "2024-10-10": "#FF624F"], timeSlots: [EdUnion.TimeSlot(colorHex: "#FF624F", timeRanges: ["08:00 - 11:00", "14:00 - 18:00"]), EdUnion.TimeSlot(colorHex: "#000000", timeRanges: ["06:00 - 21:00"])])
//}
