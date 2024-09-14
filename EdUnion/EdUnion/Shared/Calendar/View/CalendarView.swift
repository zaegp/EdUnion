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
    var selectedDate: Date  // 傳遞選中的日期
    var onSelectColor: (Color) -> Void  // 選擇顏色的回調
    
    let colors: [Color] = [.red, .green, .blue]  // 可以選擇的顏色
    
    var body: some View {
        VStack {
            Text("選擇顏色")
                .font(.headline)
                .padding()
            
            HStack(spacing: 30) {
                ForEach(colors, id: \.self) { color in
                    Button(action: {
                        onSelectColor(color)  // 當選擇顏色時，調用回調
                    }) {
                        Circle()
                            .fill(color)
                            .frame(width: 50, height: 50)
                    }
                }
            }
            .padding()
        }
    }
}

struct CalendarDayView: View {
    let day: Date
    let isSelected: Bool
    let count: Int?  // 顯示該天的事件數量
    let isCurrentMonth: Bool  // 判斷是否是當前月份
    let color: Color  // 顯示該日期的顏色
    
    var body: some View {
        VStack(spacing: 5) {
            // 顯示日期數字
            Text(day.formatted(.dateTime.day()))
                .fontWeight(.bold)
                .foregroundColor(isSelected ? .white : (isCurrentMonth ? .primary : .gray)) // 當前月份為黑色，非當前月份為灰色
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(
                    Circle()
                        .fill(isSelected ? Color.black : Color.clear)  // 如果選中則填充黑色圓圈
                )
            
            // 如果是當前月份，無論有無顏色點點，都佔用相同的空間
            if isCurrentMonth {
                // 使用 `ZStack` 來確保日期框統一高度
                ZStack {
                    Circle()
                        .fill(color != .clear ? color : Color.clear)  // 使用傳遞進來的顏色，默認透明
                        .frame(width: 8, height: 8)
                }
                .frame(height: 10)  // 固定高度
            }
            
            // 如果是當前月份且有事件，顯示事件數量
            if isCurrentMonth, let count = count {
                Circle()
                    .fill(count > 5 ? Color.red : Color.green)  // 根據事件數量變更顏色
                    .frame(width: 8, height: 8)
            }
        }
        .frame(height: 60) // 保持統一的高度
    }
}

struct CalendarView: View {
    @State private var currentDate = Date()
    let daysOfWeek = Calendar.current.shortWeekdaySymbols
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    @State private var days: [Date] = []
    
    // 單選模式
    @State private var selectedDay: Date? = nil
    
    @State private var coursesByDay: [Course] = []
    @State private var showAddCourseSheet = false
    @State private var courses: [Course] = []
    @State private var viewMode: CalendarViewMode = .month
    @State private var counts = [Int: Int]()
    
    @State private var showColorPicker: Bool = false  // 顯示顏色選擇器
    @State private var dayColors: [Date: Color] = [:]  // 每天的顏色映射
    
    var body: some View {
        VStack {
            Picker("View Mode", selection: $viewMode) {
                ForEach(CalendarViewMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            HStack {
                Button(action: {
                    previousPeriod()
                }) {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(viewMode == .month ? formattedMonthAndYear(currentDate) : formattedWeekAndYear(currentDate))
                    .font(.headline)
                Spacer()
                Button(action: {
                    nextPeriod()
                }) {
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
                    let isCurrentMonth = Calendar.current.isDate(day, equalTo: currentDate, toGranularity: .month)
                    
                    CalendarDayView(day: day,
                                    isSelected: selectedDay == day,  // 單選
                                    count: counts[Calendar.current.component(.day, from: day)],
                                    isCurrentMonth: isCurrentMonth,
                                    color: dayColors[day] ?? .clear)  // 傳遞顏色，默認為透明
                    .onTapGesture {
                        toggleSingleSelection(for: day)  // 單選模式
                    }
                    .onLongPressGesture {
                        selectedDay = day
                        showColorPicker = true  // 顯示顏色選擇器
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .onAppear(perform: setupView)
        .onChange(of: viewMode) { _ in
            setupView()
        }
        .sheet(isPresented: $showColorPicker) {
            if let selectedDay = selectedDay {
                ColorPickerView(selectedDate: selectedDay, onSelectColor: { color in
                    dayColors[selectedDay] = color  // 設置選擇的顏色
                    selectNextDay()  // 自動跳到下一天
                })
                .presentationDetents([.fraction(0.25)])  // 佔據屏幕 1/4 高度
            }
        }
    }
    
    // 單選邏輯
    private func toggleSingleSelection(for day: Date) {
        selectedDay = (selectedDay == day) ? nil : day
        filterCourses(for: day)
    }
    
    // 自動選擇下一天
    private func selectNextDay() {
        guard let currentDay = selectedDay else { return }
        
        if let nextDayIndex = days.firstIndex(of: currentDay)?.advanced(by: 1), nextDayIndex < days.count {
            selectedDay = days[nextDayIndex]  // 跳到下一天
        } else {
            selectedDay = nil  // 如果是最後一天，取消選擇
            showColorPicker = false  // 關閉顏色選擇器
        }
    }
    
    private func setupView() {
        if viewMode == .month {
            days = generateMonthDays(for: currentDate)
        } else {
            days = generateWeekDays(for: currentDate)
        }
        setupCounts()
    }
    
    private func setupCounts() {
        counts = [:]
        let currentMonth = Calendar.current.component(.month, from: currentDate)
        let currentYear = Calendar.current.component(.year, from: currentDate)
        
        let filteredCourses = courses.filter { course in
            let courseMonth = Calendar.current.component(.month, from: course.date)
            let courseYear = Calendar.current.component(.year, from: course.date)
            return courseMonth == currentMonth && courseYear == currentYear
        }
        
        let mappedItems = filteredCourses.map { (Calendar.current.component(.day, from: $0.date), 1) }
        counts = Dictionary(mappedItems, uniquingKeysWith: +)
    }
    
    // 過濾當天的課程
    private func filterCourses(for day: Date) {
        coursesByDay = courses.filter { Calendar.current.isDate($0.date, inSameDayAs: day) }
    }
    
    private func generateMonthDays(for date: Date) -> [Date] {
        guard let startOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: date)),
              let range = Calendar.current.range(of: .day, in: .month, for: startOfMonth) else {
            return []
        }
        
        var days: [Date] = []
        let firstWeekdayOfMonth = Calendar.current.component(.weekday, from: startOfMonth) - 1
        
        if let previousMonthEnd = Calendar.current.date(byAdding: .day, value: -1, to: startOfMonth) {
            for dayOffset in (0..<firstWeekdayOfMonth).reversed(){
                if let day = Calendar.current.date(byAdding: .day, value: -dayOffset, to: previousMonthEnd) {
                    days.append(day)
                }
            }
        }
        
        for day in range {
            if let date = Calendar.current.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }
        
        if let lastDayOfMonth = days.last {
            let remainingDays = 7 - (days.count % 7)
            if remainingDays < 7 {
                for dayOffset in 1...remainingDays {
                    if let day = Calendar.current.date(byAdding: .day, value: dayOffset, to: lastDayOfMonth) {
                        days.append(day)
                    }
                }
            }
        }
        
        return days
    }
    
    private func generateWeekDays(for date: Date) -> [Date] {
        let startOfWeek = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
        return (0..<7).compactMap { day -> Date? in
            Calendar.current.date(byAdding: .day, value: day, to: startOfWeek)
        }
    }
    
    private func previousPeriod() {
        if viewMode == .month {
            currentDate = Calendar.current.date(byAdding: .month, value: -1, to: currentDate)!
        } else {
            currentDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: currentDate)!
        }
        setupView()
    }
    
    private func nextPeriod() {
        if viewMode == .month {
            currentDate = Calendar.current.date(byAdding: .month, value: 1, to: currentDate)!
        } else {
            currentDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: currentDate)!
        }
        setupView()
    }
    
    private func formattedMonthAndYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func formattedWeekAndYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        let startOfWeek = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
        let endOfWeek = Calendar.current.date(byAdding: .day, value: 6, to: startOfWeek)!
        return "\(formatter.string(from: startOfWeek)) - \(formatter.string(from: endOfWeek))"
    }
}

#Preview {
    CalendarView()
}
