//
//  CalendarView.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/13.
//

struct Course: Identifiable {
    var id = UUID()
    var name: String?
    var date: Date
    var startTime: Date
    var endTime: Date
    var isCompleted: Bool = false
}

import SwiftUI

enum CalendarViewMode: String, CaseIterable {
    case week = "Week View"
    case month = "Month View"
}

struct ColorPickerView: View {
    var selectedDate: Date
    var existingColor: Color?
    var availableColors: [Color]
    var onSelectColor: (Color) -> Void

    @State private var selectedColor: Color

    init(selectedDate: Date, existingColor: Color?, availableColors: [Color], onSelectColor: @escaping (Color) -> Void) {
        self.selectedDate = selectedDate
        self.existingColor = existingColor
        self.availableColors = availableColors
        self.onSelectColor = onSelectColor
        _selectedColor = State(initialValue: existingColor ?? availableColors.first ?? .blue)
    }

    var body: some View {
        VStack {
            Text("选择颜色")
                .font(.headline)
                .padding()

            // 显示可用的颜色选项
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(availableColors, id: \.self) { color in
                        Button(action: {
                            // 立即调用 onSelectColor 并跳转到下一页
                            self.selectedColor = color
                            onSelectColor(color)  // 选择颜色后立即调用
                        }) {
                            Circle()
                                .stroke(self.selectedColor == color ? Color.blue : Color.clear, lineWidth: 2)
                                .background(Circle().fill(color))
                                .frame(width: 50, height: 50)
                        }
                    }
                }
                .padding()
            }
        }
        .padding()
    }
}

struct CalendarDayView: View {
    let day: Date?
    let isSelected: Bool
    let isCurrentMonth: Bool
    let color: Color  // 显示该日期的颜色

    var body: some View {
        VStack(spacing: 5) {
                    if let day = day {  // 安全解包，確保 day 有值
                        // 如果有日期，顯示日期數字
                        Text(day.formatted(.dateTime.day()))
                            .fontWeight(.bold)
                            .foregroundColor(isSelected ? .white : (isCurrentMonth ? .primary : .gray))
                            .frame(maxWidth: .infinity, minHeight: 40)
                            .background(
                                Circle()
                                    .fill(isSelected ? Color.black : Color.clear)
                            )
                        
                        // 如果是当前月份，显示颜色点
                        if isCurrentMonth {
                            ZStack {
                                Circle()
                                    .fill(color != .clear ? color : Color.clear)
                                    .frame(width: 8, height: 8)
                            }
                            .frame(height: 10)  // 固定高度
                        }
                    } else {
                        // 如果日期為 nil，顯示為空白
                        Text("")
                            .frame(maxWidth: .infinity, minHeight: 40)
                    }
                }
        .frame(height: 60)  // 保持统一的高度
    }
}

struct CalendarView: View {
    @State private var currentDate = Date()
    let daysOfWeek = Calendar.current.shortWeekdaySymbols
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    @State private var days: [Date?] = []
    @State private var timeSlots: [AvailableTimeSlot] = []
    @State private var availableColors: [Color] = []
    @State private var dateColors: [Date: Color] = [:]
    @State private var selectedDay: Date? = nil
    @State private var showColorPicker: Bool = false

    var body: some View {
        VStack {
            HStack {
                Button(action: { previousPeriod() }) {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(formattedMonthAndYear(currentDate))
                    .font(.headline)
                Spacer()
                Button(action: { nextPeriod() }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding()

            HStack {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .fontWeight(.black)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns) {
                ForEach(days, id: \.self) { day in
                    if let day = day {  // 確保 day 不為 nil
                        let isCurrentMonth = Calendar.current.isDate(day, equalTo: currentDate, toGranularity: .month)

                        CalendarDayView(
                            day: day,
                            isSelected: selectedDay == day,
                            isCurrentMonth: isCurrentMonth,
                            color: dateColors[day] ?? .clear  // 如果 day 為 nil，預設顏色為 .clear
                        )
                        .onTapGesture {
                            toggleSingleSelection(for: day)
                        }
                        .onLongPressGesture {
                            selectedDay = day
                            showColorPicker = true
                        }
                    } else {
                        // 對應 nil 的情況，顯示空白
                        CalendarDayView(
                            day: nil,
                            isSelected: false,
                            isCurrentMonth: false,
                            color: .clear
                        )
                    }
                }
            }
            .onAppear {
                setupView()
                fetchDateColors()
                fetchTimeSlots()
            }
        }
        .sheet(isPresented: $showColorPicker) {
                    if let selectedDay = selectedDay {
                        let existingColor = dateColors[selectedDay]
                        ColorPickerView(
                            selectedDate: selectedDay,
                            existingColor: existingColor,
                            availableColors: availableColors,
                            onSelectColor: { color in
                                dateColors[selectedDay] = color  // 更新颜色
                                FirebaseService.shared.saveDateColorToFirebase(date: selectedDay, color: color)
                                selectNextDay()  // 自动选择下一天
                            }
                        )
                        .presentationDetents([.fraction(0.25)])
                    }
                }
    }

    private func toggleSingleSelection(for day: Date) {
        selectedDay = (selectedDay == day) ? nil : day
    }
    
    private func selectNextDay() {
            guard let currentDay = selectedDay else { return }

            if let nextDayIndex = days.firstIndex(of: currentDay)?.advanced(by: 1), nextDayIndex < days.count {
                selectedDay = days[nextDayIndex]  // 跳转到下一天
            } else {
                selectedDay = nil  // 如果是最后一天，取消选择
            }
        }


    private func setupView() {
        days = generateMonthDays(for: currentDate)
    }

    private func generateMonthDays(for date: Date) -> [Date?] {
        var days: [Date?] = []
        var calendar = Calendar.current
        calendar.firstWeekday = 1  // 設置一周的第一天為星期日
        
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        
        // 获取该月的范围和天数
        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
        
        // 获取该月的第一天对应的星期几（1 = 周日，2 = 周一，... 7 = 周六）
        let firstDayOfWeek = calendar.component(.weekday, from: startOfMonth)
        
        // 前置空白天数（按周日作为一周的开始）
        let paddingDays = firstDayOfWeek - 1
        
        // 用 nil 填充前置空白
        for _ in 0..<paddingDays {
            days.append(nil)  // 添加空白
        }
        
        // 添加当前月份的天数
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }

    private func fetchTimeSlots() {
        FirebaseService.shared.fetchTimeSlots(forTeacher: "001") { result in
            switch result {
            case .success(let fetchedTimeSlots):
                DispatchQueue.main.async {
                    self.timeSlots = fetchedTimeSlots
                    self.extractAvailableColors()
                }
            case .failure(let error):
                print("获取时间段时出错：\(error)")
            }
        }
    }

    private func extractAvailableColors() {
        let colorHexes = Set(timeSlots.map { $0.colorHex })
        self.availableColors = colorHexes.map { Color(hex: $0) }
    }

    
    private func fetchDateColors() {
            let teacherRef = FirebaseService.shared.db.collection("teachers").document("001")
            
            teacherRef.getDocument { (documentSnapshot, error) in
                if let error = error {
                    print("获取日期颜色时出错：\(error)")
                } else if let document = documentSnapshot, document.exists {
                    if let data = document.data(), let selectedTimeSlots = data["selectedTimeSlots"] as? [String: String] {
                        for (dateString, colorHex) in selectedTimeSlots {
                            if let date = dateFormatter.date(from: dateString) {
                                self.dateColors[date] = Color(hex: colorHex)  // 将 hex 转换为 Color 并更新 dateColors
                            }
                        }
                    }
                }
            }
        }
    
    private let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.timeZone = TimeZone.current
            return formatter
        }()
    
    private func previousPeriod() {
        currentDate = Calendar.current.date(byAdding: .month, value: -1, to: currentDate)!
        setupView()
    }

    private func nextPeriod() {
        currentDate = Calendar.current.date(byAdding: .month, value: 1, to: currentDate)!
        setupView()
    }

    private func formattedMonthAndYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
}

#Preview {
    CalendarView()
}
