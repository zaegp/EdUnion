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
    let timeSlots: [TimeSlot]
    
    @State private var selectedDate: String?
    @State private var selectedTimes: [String] = []
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
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
                
                // 根據選擇的日期顯示對應的時間段
                if let selectedDate = selectedDate, let colorHex = selectedTimeSlots[selectedDate] {
                    let slotsForDate = timeSlots.filter { $0.colorHex == colorHex }
                    
                    if slotsForDate.isEmpty {
                        Text("無可用時間段")
                            .padding()
                    } else {
                        // 使用 LazyVGrid 來顯示時間段
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3), spacing: 20) {
                                ForEach(slotsForDate.flatMap { generateTimeSlots(from: $0.timeRanges) }, id: \.self) { timeSlot in
                                    Button(action: {
                                        toggleSelection(of: timeSlot)
                                    }) {
                                        Text(timeSlot)
                                            .frame(height: 50)
                                            .frame(maxWidth: .infinity)
                                            .background(selectedTimes.contains(timeSlot) ? .mainOrange : .background)
                                            .foregroundColor(selectedTimes.contains(timeSlot) ? .white : .black)
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
                
                // 提交預約按鈕
                Button(action: submitBooking) {
                    Text("提交預約")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background((selectedDate != nil && !selectedTimes.isEmpty) ? Color.orange : Color.gray)
                        .cornerRadius(10)
                        .padding([.horizontal, .bottom])
                }
                .disabled(selectedDate == nil || selectedTimes.isEmpty) // 禁用按鈕如果未選擇日期或時間
            }
            .navigationBarTitle("預約時間表", displayMode: .inline)
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("通知"), message: Text(alertMessage), dismissButton: .default(Text("確定")))
            }
        }
    }
    
    // 將日期轉換為 "yyyy-MM-dd" 格式字串
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    // 解析時間範圍並生成所有 30 分鐘間隔的時間點
    func generateTimeSlots(from timeRanges: [String]) -> [String] {
        var timeSlots: [String] = []
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        for range in timeRanges {
            let times = range.split(separator: "-").map { $0.trimmingCharacters(in: .whitespaces) }
            
            if let startTime = dateFormatter.date(from: String(times[0])),
               let endTime = dateFormatter.date(from: String(times[1])) {
                var currentTime = startTime
                
                while currentTime < endTime {
                    timeSlots.append(dateFormatter.string(from: currentTime))
                    // 增加 30 分鐘
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
    
    // 切換選擇的時間槽
    func toggleSelection(of timeSlot: String) {
        if let index = selectedTimes.firstIndex(of: timeSlot) {
            selectedTimes.remove(at: index)
        } else {
            selectedTimes.append(timeSlot)
        }
    }
    
    // 提交預約的函數
    func submitBooking() {
        guard let date = selectedDate, !selectedTimes.isEmpty else {
            alertMessage = "請選擇日期和至少一個時間段。"
            showingAlert = true
            return
        }
        
        let bookingData: [String: Any] = [
            "studentID": "002",
            "teacherID": "001",
            "date": date,
            "times": selectedTimes,
            "status": "pending",
            "timestamp": Timestamp(date: Date())
        ]
        
        FirebaseService.shared.saveBooking(data: bookingData) { success, error in
            if success {
                alertMessage = "預約成功！"
                showingAlert = true
                selectedDate = nil
                selectedTimes = []
            } else {
                alertMessage = "預約失敗：\(error?.localizedDescription ?? "未知錯誤")"
                showingAlert = true
            }
        }
    }
}

#Preview {
    BookingView(selectedTimeSlots: ["2024-09-11": "#FF624F", "2024-09-13": "#FF624F", "2024-09-12": "#000000", "2024-10-10": "#FF624F"], timeSlots: [EdUnion.TimeSlot(colorHex: "#FF624F", timeRanges: ["08:00 - 11:00", "14:00 - 18:00"]), EdUnion.TimeSlot(colorHex: "#000000", timeRanges: ["06:00 - 21:00"])])
}


//struct BookingView: View {
//    // 當前選擇的日期，將初始值設置為一個有時間段的日期
//    @State private var selectedDate = Calendar.current.date(from: DateComponents(year: 2024, month: 9, day: 27)) ?? Date()
//
//    // 傳入的時間段和選擇的時間段顏色
//    let selectedTimeSlots: [String: String] // 日期對應顏色
//    let timeSlots: [TimeSlot] // 顏色對應的時間段
//
//    var body: some View {
//        NavigationView {
//            VStack {
//                // 日期選擇器
//                DatePicker("選擇日期", selection: $selectedDate, displayedComponents: .date)
//                    .datePickerStyle(.compact)
//                    .padding()
//
//                // 取得選擇日期的字串格式
//                let selectedDateString = formattedDate(selectedDate)
//
//                // 根據選擇的日期找到對應的顏色
//                let colorHex = selectedTimeSlots[selectedDateString] ?? "#FFFFFF"
//                let slotsForDate = timeSlots.filter { $0.colorHex == colorHex }
//
//                // 檢查是否有匹配的時間段
//                if slotsForDate.isEmpty {
//                    Text("無可用時間段")
//                        .padding()
//                } else {
//                    // 使用 LazyVGrid 來顯示時間段
//                    ScrollView(.vertical, showsIndicators: false) {
//                        LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3), spacing: 20) {
//                            // 顯示該日期的所有時間段
//                            ForEach(slotsForDate.flatMap { $0.timeRanges }, id: \.self) { timeRange in
//                                Button(timeRange) {
//                                    // 處理時間選擇
//                                    print("選擇了時間: \(timeRange)")
//                                }
//                                .frame(height: 50)
//                                .frame(maxWidth: .infinity)
//                                .background(Color(hex: colorHex)) // 根據時間段的顏色設定背景
//                                .foregroundColor(.white)
//                                .cornerRadius(10)
//                            }
//                        }
//                    }
//                }
//            }
//            .navigationBarTitle("預約時間表", displayMode: .inline)
//        }
//    }
//
//    // 將日期轉換為 "yyyy-MM-dd" 格式字串
//    func formattedDate(_ date: Date) -> String {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "yyyy-MM-dd"
//        return formatter.string(from: date)
//    }
//}
