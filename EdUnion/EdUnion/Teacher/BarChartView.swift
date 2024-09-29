//
//  BarChartView.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/29.
//

import SwiftUI
import FirebaseFirestore
import Combine

struct LessonData: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}
class LessonDataManager: ObservableObject {
    @Published var lessonData: [LessonData] = []
    @Published var selectedRange: RangeType = .week
    @Published var selectedData: LessonData?
    @Published var appointments: [Appointment] = []
    @Published var currentWeekOffset: Int = 0 // 用於跟踪週的偏移量

    let userID = UserSession.shared.currentUserID
    
    init() {
        fetchAppointments()
    }
    
    func fetchAppointments() {
        // 假設您已經初始化了 Firestore
        let firestore = Firestore.firestore()
        
        firestore.collection("appointments")
            .whereField("teacherID", isEqualTo: userID)
            .getDocuments { (snapshot, error) in
                if let error = error {
                    print("Error fetching appointments: \(error.localizedDescription)")
                    return
                }
                
                var fetchedAppointments: [Appointment] = []
                for document in snapshot?.documents ?? [] {
                    do {
                        var appointment = try document.data(as: Appointment.self)
                        appointment.id = document.documentID // 設置 id
                        fetchedAppointments.append(appointment)
                    } catch {
                        print("Error decoding appointment: \(error)")
                    }
                }
                
                DispatchQueue.main.async {
                    self.appointments = fetchedAppointments
                    self.generateData()
                }
            }
    }
    
    func generateData() {
        // 根據選擇的範圍統計課程資料
        switch selectedRange {
        case .week:
            lessonData = generateWeeklyData()
        case .month:
            lessonData = generateMonthlyData()
        case .year:
            lessonData = generateYearlyData()
        }
    }
    
    func generateWeeklyData() -> [LessonData] {
            var data: [LessonData] = []
            let calendar = Calendar.current
            let today = Date()

            // 根據 currentWeekOffset 計算目標週的開始日期
            guard let targetWeekStart = calendar.date(byAdding: .weekOfYear, value: currentWeekOffset, to: today),
                  let weekInterval = calendar.dateInterval(of: .weekOfYear, for: targetWeekStart) else {
                return data
            }

            for i in 0..<7 {
                if let date = calendar.date(byAdding: .day, value: i, to: weekInterval.start) {
                    let count = appointments.filter { appointment in
                        isSameDay(date1: date, date2: appointment.timestamp)
                    }.count
                    data.append(LessonData(date: date, count: count))
                }
            }
            return data
        }
    
    func generateMonthlyData() -> [LessonData] {
        var data: [LessonData] = []
        let calendar = Calendar.current
        let today = Date()
        // 獲取本月的日期範圍
        guard let monthInterval = calendar.dateInterval(of: .month, for: today) else {
            return data
        }
        
        // 按周統計，一個月大約4-5周
        for i in 0..<5 {
            if let startOfWeek = calendar.date(byAdding: .weekOfYear, value: i, to: monthInterval.start) {
                let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? startOfWeek
                let count = appointments.filter { appointment in
                    appointment.timestamp >= startOfWeek && appointment.timestamp <= endOfWeek
                }.count
                data.append(LessonData(date: startOfWeek, count: count))
            }
        }
        return data
    }
    
    func generateYearlyData() -> [LessonData] {
        var data: [LessonData] = []
        let calendar = Calendar.current
        let today = Date()
        // 獲取本年的日期範圍
        guard let yearInterval = calendar.dateInterval(of: .year, for: today) else {
            return data
        }
        
        for i in 0..<12 {
            if let date = calendar.date(byAdding: .month, value: i, to: yearInterval.start) {
                // 修改的部分
                if let range = calendar.range(of: .day, in: .month, for: date) {
                    let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
                    let endOfMonth = calendar.date(byAdding: .day, value: range.count - 1, to: startOfMonth) ?? date
                    let count = appointments.filter { appointment in
                        appointment.timestamp >= startOfMonth && appointment.timestamp <= endOfMonth
                    }.count
                    data.append(LessonData(date: date, count: count))
                } else {
                    print("无法获取日期 \(date) 的天数范围")
                }
            }
        }
        return data
    }
    
    func isSameDay(date1: Date, date2: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(date1, inSameDayAs: date2)
    }
}

enum RangeType: String, CaseIterable, Identifiable {
    case week = "周"
    case month = "月"
    case year = "年"
    
    var id: String { self.rawValue }
}

struct BarChartView: View {
    @ObservedObject var dataManager: LessonDataManager

    var body: some View {
        VStack {
            // 範圍選擇器
            Picker("範圍", selection: $dataManager.selectedRange) {
                ForEach(RangeType.allCases) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            // 顯示選擇的數據詳細信息
            if let selectedData = dataManager.selectedData {
                if dataManager.selectedRange == .month {
                    Text("週日期範圍：\(formattedWeekRange(selectedData.date))，課程數量：\(selectedData.count)")
                        .padding()
                } else {
                    Text("日期：\(formattedDate(selectedData.date))，課程數量：\(selectedData.count)")
                        .padding()
                }
            }

            // 柱狀圖
            GeometryReader { geometry in
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(dataManager.lessonData) { data in
                        BarView(data: data, maxValue: maxValue(), selectedData: $dataManager.selectedData, rangeType: dataManager.selectedRange)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            if value.translation.width < 0 {
                                // 向左滑動，切換到下一週
                                dataManager.currentWeekOffset += 1
                            } else if value.translation.width > 0 {
                                // 向右滑動，切換到上一週
                                dataManager.currentWeekOffset -= 1
                            }
                            dataManager.generateData()
                        }
                )
            }
            .padding()
        }
        .onChange(of: dataManager.selectedRange) { _ in
            dataManager.generateData()
        }
    }

    func maxValue() -> Int {
        dataManager.lessonData.map { $0.count }.max() ?? 1
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    func formattedWeekRange(_ date: Date) -> String {
        let calendar = Calendar.current
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) else {
            return ""
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return "\(formatter.string(from: weekInterval.start)) - \(formatter.string(from: weekInterval.end))"
    }
}

struct BarView: View {
    var data: LessonData
    var maxValue: Int
    @Binding var selectedData: LessonData?
    var rangeType: RangeType
    
    var body: some View {
        VStack {
            Spacer()
            Rectangle()
                .fill(Color.blue)
                .frame(height: barHeight())
                .onTapGesture {
                    selectedData = data
                }
            Text(formattedLabel())
                .font(.caption)
        }
    }
    
    func barHeight() -> CGFloat {
        let height = CGFloat(Double(data.count) / Double(maxValue)) * 200 // 200 為柱狀圖的最大高度
        return height.isNaN ? 0 : height
    }
    
    func formattedLabel() -> String {
        let formatter = DateFormatter()
        switch rangeType {
        case .week:
            formatter.dateFormat = "E" // 週幾
        case .month:
            formatter.dateFormat = "'週'W" // 第幾週
        case .year:
            formatter.dateFormat = "MMM" // 月份縮寫
        }
        return formatter.string(from: data.date)
    }
}

struct ContentViews: View {
    @StateObject var dataManager = LessonDataManager()
    
    var body: some View {
        BarChartView(dataManager: dataManager)
    }
}

#Preview {
    ContentViews()
}
