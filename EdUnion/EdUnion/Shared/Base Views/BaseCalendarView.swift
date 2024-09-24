//
//  BaseCalendarView.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/19.
//

import SwiftUI
import FirebaseFirestore

var tag = 1

class CalendarService {
    static let shared = CalendarService()
    var activitiesByDate: [Date: [Appointment]] = [:]
    
    private init() {}  
}

struct CalendarDayView: View {
    let day: Date?
    let isSelected: Bool
    let isCurrentMonth: Bool
    let color: Color

    var body: some View {
        VStack(spacing: 5) {
            if let day = day {
                let isPastDate = Calendar.current.isDateInYesterdayOrEarlier(day)
                
                Text(day.formatted(.dateTime.day()))
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? .white : (isPastDate ? .gray : (isCurrentMonth ? .primary : .gray)))
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.black : Color.clear)
                    )
                
                ZStack {
                    // 去掉過去日期的檢查，直接顯示顏色點點
                    Circle()
                        .fill(color != .clear ? color : Color.clear)
                        .frame(width: 8, height: 8)
                }
                .frame(height: 10)  // 保持每個日期的圓點佔位符高度一致
            } else {
                Text("")
                    .frame(maxWidth: .infinity, minHeight: 40)
                
                ZStack {
                    // 空的圓點佔位符，確保所有日期佈局一致
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 8, height: 8)
                }
                .frame(height: 10)
            }
        }
        .frame(height: 60)
    }
}
struct BaseCalendarView: View {
    
    @Binding var externalDateColors: [Date: Color]?
    @State private var internalDateColors: [Date: Color] = [:]  // 本地狀態
    @ObservedObject var viewModel: BaseCalendarViewModel
    @State private var isDataLoaded = false
    @State private var isShowingDetail = false
    @State private var selectedAppointment: Appointment?
    @State private var appointmentListener: ListenerRegistration?
    
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
        let colors = dateColors
        VStack {
            HStack {
                Button(action: { previousPeriod() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Color(.backButton))
                }
                Spacer()
                Text(formattedMonthAndYear(currentDate))
                    .font(.headline)
                Spacer()
                Button(action: { nextPeriod() }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color(.backButton))
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
                if !isDataLoaded {
                    fetchAppointments()
                    isDataLoaded = true
                }
            }
            
            Spacer()
            
            if let selectedDay = selectedDay, let activities = CalendarService.shared.activitiesByDate[Calendar.current.startOfDay(for: selectedDay)] {
                ZStack {
                    Color.white
                        .edgesIgnoringSafeArea(.all)
                    
                    List {
                        ForEach(activities) { appointment in
                            HStack {
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text(viewModel.teacherNames[appointment.teacherID] ?? "")
                                            .onAppear {
                                                if viewModel.teacherNames[appointment.teacherID] == nil {
                                                    viewModel.fetchTeacherName(for: appointment.teacherID)
                                                }
                                            }
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                        
                                        Spacer() // 保持時間靠右
                                        
                                        Text(TimeService.convertCourseTimeToDisplay(from: appointment.times))
                                            .font(.body)
                                            .foregroundColor(.black)
                                    }
                                }
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                                        .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color(uiColor: .systemBackground))
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                            .padding(.vertical, 5)
                            .listRowSeparator(.hidden)
                            .onTapGesture {
                                selectedAppointment = appointment
                                isShowingDetail = true
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .background(Color.clear)
                    .sheet(isPresented: $isShowingDetail) {
                                if let selectedAppointment = selectedAppointment {
                                    DetailView(appointment: selectedAppointment)  // 展示詳細頁
                                }
                            }
                }
            }
        }
    }
    
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
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
    
    // 要換
    private func fetchAppointments() {
        appointmentListener?.remove()
        
        appointmentListener = AppointmentFirebaseService.shared.fetchConfirmedAppointments(forTeacherID: nil, studentID: studentID) { result in
            switch result {
            case .success(let fetchedAppointments):
                DispatchQueue.main.async {
                    self.appointments = fetchedAppointments
                    self.mapAppointmentsToDates()  // 更新 UI 或處理預約資料
                }
            case .failure(let error):
                print("獲取預約時出錯：\(error)")
            }
        }
    }
    
    private func mapAppointmentsToDates() {
        CalendarService.shared.activitiesByDate.removeAll()
        var seenAppointments = Set<String>()
        var duplicateAppointments = [Appointment]()
        
        for appointment in appointments {
            if seenAppointments.contains(appointment.id!) {
                // 如果重複，將該預約加入到重複列表
                duplicateAppointments.append(appointment)
            } else {
                // 如果不重複，將 id 加入已處理的列表
                seenAppointments.insert(appointment.id!)
            }
            
            if let date = dateFormatter.date(from: appointment.date) {
                let startOfDay = Calendar.current.startOfDay(for: date)
                if CalendarService.shared.activitiesByDate[startOfDay] != nil {
                    CalendarService.shared.activitiesByDate[startOfDay]?.append(appointment)
                } else {
                    CalendarService.shared.activitiesByDate[startOfDay] = [appointment]
                }
            }
        }
        
        // 打印重複的預約
        if !duplicateAppointments.isEmpty {
            print("重複的預約: \(duplicateAppointments.map { $0.id })")
        }
        
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
