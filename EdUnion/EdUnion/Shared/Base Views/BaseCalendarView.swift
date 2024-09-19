//
//  BaseCalendarView.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/19.
//

import SwiftUI

var tag = 1

class CalendarService {
    static let shared = CalendarService()
    var activitiesByDate: [Date: [Appointment]] = [:]

    private init() {}  // 私有構造函數，確保是單例
}

struct CalendarDayView: View {
    let day: Date?
    let isSelected: Bool
    let isCurrentMonth: Bool
    let color: Color
    
    var body: some View {
        VStack(spacing: 5) {
            if let day = day {
                Text(day.formatted(.dateTime.day()))
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? .white : (isCurrentMonth ? .primary : .gray))
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.black : Color.clear)
                    )
                
                if isCurrentMonth {
                    ZStack {
                        Circle()
                            .fill(color != .clear ? color : Color.clear)
                            .frame(width: 8, height: 8)
                    }
                    .frame(height: 10)
                }
            } else {
                Text("")
                    .frame(maxWidth: .infinity, minHeight: 40)
            }
        }
        .frame(height: 60)
    }
}

struct BaseCalendarView: View {
    
    @Binding var externalDateColors: [Date: Color]?
        @State private var internalDateColors: [Date: Color] = [:]  // 本地狀態

        // 這裡選擇使用外部綁定還是本地狀態
        var dateColors: [Date: Color] {
            get {
                externalDateColors ?? internalDateColors
            }
            set {
                if externalDateColors != nil {
                    externalDateColors = newValue
                } else {
                    internalDateColors = newValue
                }
            }
        }
    
    @State private var selectedDay: Date? = nil
    
    @State private var appointments: [Appointment] = []  // 從 Firebase 獲取的預約資料
    /*@State private var activitiesByDate: [Date: [Appointment]] = [:]*/  // 按日期分類的活動
    
    var onDayTap: ((Date) -> Void)? = nil
        var onDayLongPress: ((Date) -> Void)? = nil

    @State private var currentDate = Date()
    let daysOfWeek = Calendar.current.shortWeekdaySymbols
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    @State private var days: [Date?] = []

    var body: some View {
        let colors = dateColors ?? [:]
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
                    if let day = day {
                        let isCurrentMonth = Calendar.current.isDate(day, equalTo: currentDate, toGranularity: .month)
            
                                    
                                    CalendarDayView(
                                        day: day,
                                        isSelected: selectedDay == day,
                                        isCurrentMonth: isCurrentMonth,
                                        color: dateColors[day] ?? .clear
                                    )
                        .onTapGesture {
                            print("點擊了日期：\(day)")  // 調試語句，確認事件是否被觸發
                            toggleSingleSelection(for: day)  // 處理內部日期選擇邏輯
                            onDayTap?(day)  // 如果外部傳入了 onDayTap 閉包，則調用
                        }
                        .onLongPressGesture {
                            onDayLongPress?(day) 
                            selectedDay = day// 長按事件
                        }
                    } else {
                        CalendarDayView(day: nil, isSelected: false, isCurrentMonth: false, color: .clear)
                    }
                }
            
            }
            .onAppear {
                setupView()
                fetchAppointments()  // 視圖顯示時獲取 Firebase 預約資料
            }

            Spacer()

            if let selectedDay = selectedDay, let activities = CalendarService.shared.activitiesByDate[Calendar.current.startOfDay(for: selectedDay)] {
                ZStack {
                    Color.white
                        .edgesIgnoringSafeArea(.all)

                    List {
                        ForEach(activities) { appointment in
                            ForEach(appointment.times, id: \.self) { time in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("學生 ID: \(appointment.studentID)")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)

                                        Text(time)
                                            .font(.body)
                                            .padding(.top, 5)
                                    }
                                    Spacer()
                                }
                                .padding()
                                .background(Color(uiColor: .systemBackground))
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                                .padding(.vertical, 5)
                                .listRowSeparator(.hidden)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .background(Color.clear)
                }
            }
        }
    }

    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"  // 根據需要設置格式，例如 "HH:mm"
        return formatter.string(from: date)
    }
    
    private func toggleSingleSelection(for day: Date) {
        selectedDay = (selectedDay == day) ? nil : day
    }

    private func setupView() {
        days = generateMonthDays(for: currentDate)
    }

    private func generateMonthDays(for date: Date) -> [Date?] {
        var days: [Date?] = []
        var calendar = Calendar.current
        calendar.firstWeekday = 1

        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!

        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!

        let firstDayOfWeek = calendar.component(.weekday, from: startOfMonth)

        let paddingDays = firstDayOfWeek - 1

        for _ in 0..<paddingDays {
            days.append(nil)
        }

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }

        return days
    }

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

    // 從 Firebase 獲取預約資料
    private func fetchAppointments() {
        AppointmentFirebaseService.shared.fetchConfirmedAppointments(forTeacherID: teacherID) { result in
            switch result {
            case .success(let fetchedAppointments):
                DispatchQueue.main.async {
                    self.appointments = fetchedAppointments
                    self.mapAppointmentsToDates()  // 將預約資料按日期分類
                }
            case .failure(let error):
                print("獲取預約時出錯：\(error)")
            }
        }
    }

    // 將預約按日期分類，放入 activitiesByDate 中
    private func mapAppointmentsToDates() {
//        CalendarService.shared.activitiesByDate.removeAll()
        
        for appointment in appointments {
            if let date = dateFormatter.date(from: appointment.date) {
                let startOfDay = Calendar.current.startOfDay(for: date)
                if CalendarService.shared.activitiesByDate[startOfDay] != nil {
                    CalendarService.shared.activitiesByDate[startOfDay]?.append(appointment)
                } else {
                    CalendarService.shared.activitiesByDate[startOfDay] = [appointment]
                }
            }
        }
        print("111111")
        print(CalendarService.shared.activitiesByDate)
        print("2222222")
        
        for (date, appointments) in CalendarService.shared.activitiesByDate {
            let hasPending = appointments.contains { $0.status.lowercased() == "pending" }
            let hasConfirmed = appointments.contains { $0.status.lowercased() == "confirmed" }
            
            if hasPending {
                internalDateColors[date] = .red
            } else if hasConfirmed {
                internalDateColors[date] = .green
            } else {
                internalDateColors[date] = .clear
            }
        }
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter
    }()
}


//#Preview {
//    BaseCalendarView()
//}
