//
//  BookingView.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/15.
//

import SwiftUI

struct BookingView: View {
    let selectedTimeSlots: [String: String]
    let timeSlots: [TimeSlot] 
    
    @State private var selectedDate: String?
    
   
    var availableDates: [String] {
        return Array(selectedTimeSlots.keys).sorted()
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // 自定義的日期選擇器，顯示可選日期
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHGrid(rows: [GridItem(.flexible())], spacing: 15) {
                        ForEach(availableDates, id: \.self) { date in
                            Button(action: {
                                selectedDate = date
                            }) {
                                Text(date)
                                    .padding()
                                    .background(selectedDate == date ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(.white)
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
                                    Button(timeSlot) {
                                        // 處理時間選擇
                                        print("選擇了時間: \(timeSlot)")
                                    }
                                    .frame(height: 50)
                                    .frame(maxWidth: .infinity)
                                    .background(Color(hex: colorHex)) // 根據時間段的顏色設定背景
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                }
                            }
                        }
                    }
                } else {
                    Text("請選擇日期")
                        .padding()
                }
            }
            .navigationBarTitle("預約時間表", displayMode: .inline)
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
            
            if let startTime = dateFormatter.date(from: times[0]),
               let endTime = dateFormatter.date(from: times[1]) {
                var currentTime = startTime
                
                while currentTime < endTime {
                    timeSlots.append(dateFormatter.string(from: currentTime))
                    // 增加 30 分鐘
                    currentTime = Calendar.current.date(byAdding: .minute, value: 30, to: currentTime)!
                }
            }
        }
        return timeSlots
    }
}


// 轉換Hex顏色為SwiftUI的Color

#Preview {
    BookingView(selectedTimeSlots: ["2024-09-27": "#007AFE", "2024-09-26": "#FEA57C", "2024-09-25": "#b92d5d"], timeSlots: [EdUnion.TimeSlot(colorHex: "#007AFE", timeRanges: ["13:30 - 14:00"]), EdUnion.TimeSlot(colorHex: "#b92d5d", timeRanges: ["14:30 - 15:00", "16:30 - 19:00"]), EdUnion.TimeSlot(colorHex: "#FEA57C", timeRanges: ["00:00 - 00:30"]), EdUnion.TimeSlot(colorHex: "#000000", timeRanges: ["23:00 - 23:30", "11:00 - 11:30", "11:30 - 12:00"])])
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
