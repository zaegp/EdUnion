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

struct CalendarDay: Identifiable {
    let id = UUID()
    let date: Date?
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
                let isToday = Calendar.current.isDateInToday(day)
                
                Text(day.formatted(.dateTime.day()))
                    .fontWeight(.bold)
                    .foregroundColor(
                        isToday && isSelected
                        ? Color(UIColor.systemBackground)
                        : isSelected
                        ? Color(UIColor.label)
                        : isToday
                        ? Color.mainOrange
                        : Color(UIColor.systemBackground)
                    )
                    .strikethrough(isPastDate, color: Color(UIColor.systemBackground))
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .background(
                        ZStack {
                            if !isToday {
                                Circle()
                                    .fill(isSelected ? Color.myBackground : Color.clear)
                            } else {
                                Circle()
                                    .fill(isSelected ? Color.mainOrange : Color.clear)
                            }
                        }
                    )
                
                ZStack {
                    Circle()
                        .fill(color != .clear ? color : Color.clear)
                        .frame(width: 8, height: 8)
                }
                .frame(height: 10)
            } else {
                Text("")
                    .frame(maxWidth: .infinity, minHeight: 40)
                
                ZStack {
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
    @State private var internalDateColors: [Date: Color] = [:]
    @ObservedObject var viewModel: BaseCalendarViewModel
    @State private var isDataLoaded = false
    @State private var isShowingDetail = false
    @State private var selectedAppointment: Appointment?
    @State private var appointmentListener: ListenerRegistration?
    let userID = UserSession.shared.currentUserID
    let userRole = UserDefaults.standard.string(forKey: "userRole") ?? "teacher"
    @State private var isShowingCard = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
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
    
    //    @State private var selectedDay: Date? = nil
    @State private var selectedDay: Date? = Calendar.current.startOfDay(for: Date())
    
    @State private var appointments: [Appointment] = []
    
    var onDayTap: ((Date) -> Void)? = nil
    var onDayLongPress: ((Date) -> Void)? = nil
    
    @State private var currentDate = Date()
    let daysOfWeek = Calendar.current.shortWeekdaySymbols
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    @State private var days: [CalendarDay] = []
    @State private var isShowingChat = false
    @State private var selectedStudentID: String = ""
    @State private var isShowingNotePopup = false
    @State private var noteText = ""
    
    @State private var isWeekView: Bool = false
    
    var body: some View {
        let colors = dateColors
        ZStack {
            VStack {
                VStack {
                    HStack {
                        Button(action: { previousPeriod() }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(Color(UIColor.systemBackground))
                        }
                        Spacer()
                        Text(formattedMonthAndYear(selectedDay ?? currentDate))
                            .font(.headline)
                            .foregroundColor(Color(UIColor.systemBackground))
                        Spacer()
                        Button(action: { nextPeriod() }) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(Color(UIColor.systemBackground))
                        }
                    }
                    .padding()
                    
                    HStack {
                        ForEach(daysOfWeek, id: \.self) { day in
                            Text(day)
                                .fontWeight(.regular)
                                .frame(maxWidth: .infinity)
                                .foregroundColor(Color.myGray)
                        }
                    }
                    
                    LazyVGrid(columns: columns) {
                        ForEach(days) { calendarDay in
                            if let day = calendarDay.date {
                                let isCurrentMonth = Calendar.current.isDate(day, equalTo: currentDate, toGranularity: .month)
                                
                                CalendarDayView(
                                    day: day,
                                    isSelected: selectedDay != nil && Calendar.current.isDate(selectedDay!, inSameDayAs: day),
                                    isCurrentMonth: isCurrentMonth,
                                    color: dateColors[day] ?? .clear
                                )
                                .onTapGesture {
                                    toggleSingleSelection(for: day)
                                    onDayTap?(day)
                                }
                                .onLongPressGesture {
                                    onDayLongPress?(day)
                                }
                            } else {
                                CalendarDayView(day: nil, isSelected: false, isCurrentMonth: false, color: .clear)
                            }
                        }
                    }
                    .frame(height: isWeekView ? 80 : nil)
                    .animation(.easeInOut(duration: 0.3), value: isWeekView)
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
                                feedbackGenerator.prepare()
                                
                                if abs(value.translation.width) > abs(value.translation.height) {
                                    if value.translation.width < 0 {
                                        nextPeriod()
                                        feedbackGenerator.impactOccurred()
                                    } else if value.translation.width > 0 {
                                        previousPeriod()
                                        feedbackGenerator.impactOccurred()
                                    }
                                } else {
                                    withAnimation {
                                        if value.translation.height < 0 {
                                            if !isWeekView {
                                                isWeekView = true
                                                generateDays(for: selectedDay ?? currentDate)
                                                feedbackGenerator.impactOccurred()
                                            }
                                        } else if value.translation.height > 0 {
                                            // 向下滑動，切換到月視圖
                                            if isWeekView {
                                                isWeekView = false
                                                generateDays(for: selectedDay ?? currentDate)
                                                feedbackGenerator.impactOccurred()
                                            }
                                        }
                                    }
                                }
                            }
                    )
                    .onAppear {
                        setupView()
                        generateDays(for: selectedDay ?? currentDate)
                        if !isDataLoaded {
                            fetchAppointments()
                            isDataLoaded = true
                        }
                    }
                }
                .padding()
                .background(Color.myDarkGray)
                .cornerRadius(30)
                .padding()
                
                Spacer()
                
                if let selectedDay = selectedDay, let activities = CalendarService.shared.activitiesByDate[Calendar.current.startOfDay(for: selectedDay)] {
                    List {
                        ForEach(viewModel.sortedActivities) { appointment in
                            HStack {
                                VStack(alignment: .leading) {
                                    HStack {
                                        if userRole == "teacher" {
                                            Text(viewModel.participantNames[appointment.studentID] ?? "")
                                                .onAppear {
                                                    if viewModel.participantNames[appointment.studentID] == nil {
                                                        viewModel.fetchUserData(from: "students", userID: appointment.studentID, as: Student.self)
                                                    }
                                                }
                                                .font(.headline)
                                                .foregroundColor(Color(UIColor.myDarkGray))
                                        } else {
                                            Text(viewModel.participantNames[appointment.teacherID] ?? "")
                                                .onAppear {
                                                    if viewModel.participantNames[appointment.studentID] == nil {
                                                        viewModel.fetchUserData(from: "teachers", userID: appointment.teacherID, as: Teacher.self)
                                                    }
                                                }
                                                .font(.headline)
                                                .foregroundColor(Color(UIColor.myDarkGray))
                                        }
                                        
                                        Text(TimeService.convertCourseTimeToDisplay(from: appointment.times))
                                            .font(.body)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                    }
                                }
                                Spacer()
                                
                                Image(systemName: "arrow.forward")
                                    .foregroundColor(.primary)
                            }
                            .padding(.vertical, 5)
                            .padding(.horizontal, 10)
                            .background(.clear)
                            .cornerRadius(20)
                            //                            .overlay(
                            //                                RoundedRectangle(cornerRadius: 20)
                            //                                    .stroke(Color.myBorder, lineWidth: 1)
                            //                            )
                            //                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                            .padding(.vertical, 5)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.myBackground)
                            .frame(height: 40)
                            .onTapGesture {
                                selectedAppointment = appointment
                                isShowingCard = true
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .onAppear {
                        viewModel.loadAndSortActivities(for: activities)
                    }
                    .onChange(of: selectedDay) { newDay in
                        let newActivities = CalendarService.shared.activitiesByDate[Calendar.current.startOfDay(for: newDay)]
                        if let newActivities = newActivities {
                            viewModel.loadAndSortActivities(for: newActivities)
                        }
                    }
                    .padding(.bottom, 80)
                }
            }
            .background(Color.myBackground)
            
            if isShowingCard, let appointment = selectedAppointment {
                VStack {
                    Spacer()
                    VStack(spacing: 24) {
                        Text(appointment.date)
                            .font(.headline)
                        if userRole == "student" {
                            Text(viewModel.participantNames[appointment.teacherID] ?? "Unknown")
                                .font(.title)
                                .fontWeight(.semibold)
                        } else {
                            Text(viewModel.participantNames[appointment.studentID] ?? "Unknown")
                                .font(.title)
                                .fontWeight(.semibold)
                        }
                        Text(TimeService.convertCourseTimeToDisplay(from: appointment.times))
                            .font(.subheadline)
                        
                        if userRole == "student" {
                            Button(action: {
                                let appointmentID = appointment.id ?? ""
                                cancelAppointment(appointmentID: appointmentID)
                            }) {
                                Text("取消預約")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.mainOrange)
                                    .cornerRadius(10)
                            }
                        } else if userRole == "teacher" {
                            Button(action: {
                                selectedStudentID = appointment.studentID
                                isShowingNotePopup = true
                            }) {
                                Text("顯示備註")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.mainOrange)
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding()
                    .background(Color.myBackground)
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                    .padding()
                    Spacer()
                }
                .background(
                    Color.primary.opacity(0.2)
                )
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    isShowingCard = false
                }
            }
        }
        .overlay(
            ZStack {
                if isShowingNotePopup {
                    NotePopupViewWrapper(
                        onSave: { text in
                            noteText = text
                            isShowingNotePopup = false
                        },
                        onCancel: {
                            isShowingNotePopup = false
                        }
                    )
                    .edgesIgnoringSafeArea(.all)
                }
            }
        )
        
        
    }
    
    func generateDays(for referenceDate: Date) {
        days.removeAll()
        
        let calendar = Calendar.current
        
        if isWeekView {
            // 找到該週的第一天（通常是週日或週一，取決於日曆設定）
            guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: referenceDate)) else {
                return
            }
            for i in 0..<7 {
                if let date = calendar.date(byAdding: .day, value: i, to: startOfWeek) {
                    days.append(CalendarDay(date: date))
                }
            }
        } else {
            // 生成整個月的日期
            guard let range = calendar.range(of: .day, in: .month, for: referenceDate) else { return }
            let numDays = range.count
            
            // 找到這個月的第一天
            guard let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: referenceDate)) else { return }
            let weekdayOfFirstDay = calendar.component(.weekday, from: firstDayOfMonth)
            
            // 計算需要填充的前導空白
            let leadingEmptyDays = (weekdayOfFirstDay + 6) % 7
            
            // 填充前導空白
            for _ in 0..<leadingEmptyDays {
                days.append(CalendarDay(date: nil))
            }
            
            // 填充當月的日期
            for day in 1...numDays {
                if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                    days.append(CalendarDay(date: date))
                }
            }
        }
        
        // 調試打印
        print("Generated days for \(referenceDate):")
        for day in days {
            if let day = day.date {
                print(day)
            } else {
                print("nil")
            }
        }
    }
    
    func cancelAppointment(appointmentID: String) {
        AppointmentFirebaseService.shared.updateAppointmentStatus(appointmentID: appointmentID, status: .canceled) { result in
            switch result {
            case .success:
                alertMessage = "已送出取消預約請求"
                showingAlert = true
                isShowingCard = false
                
                if let selectedDay = selectedDay {
                    updateAppointmentsForDay(selectedDay)
                }

            case .failure(let error):
                print("更新預約狀態失敗: \(error.localizedDescription)")
            }
        }
    }

    func updateAppointmentsForDay(_ day: Date) {
        let startOfDay = Calendar.current.startOfDay(for: day)
        
        if let appointmentsForDay = CalendarService.shared.activitiesByDate[startOfDay] {
            let hasConfirmedAppointments = appointmentsForDay.contains { $0.status.lowercased() == "confirmed" }
            
            if !hasConfirmedAppointments {
                internalDateColors.removeValue(forKey: startOfDay)
            }
        } else {
            internalDateColors.removeValue(forKey: startOfDay)
        }
        
        generateDays(for: selectedDay ?? currentDate)
    }
    
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    func toggleSingleSelection(for day: Date) {
        if selectedDay == day {
            selectedDay = nil
        } else {
            selectedDay = day
        }
        print("Selected Day: \(selectedDay)")
        
        if isWeekView {
            withAnimation {
                generateDays(for: selectedDay ?? currentDate)
            }
        }
    }
    
    private func setupView() {
        generateDays(for: currentDate)
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
    
    func previousPeriod() {
        if isWeekView {
            if let selectedDay = selectedDay {
                if let newSelectedDay = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: selectedDay) {
                    self.selectedDay = newSelectedDay
                    generateDays(for: newSelectedDay)
                }
            } else {
                if let newCurrentDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: currentDate) {
                    self.currentDate = newCurrentDate
                    generateDays(for: newCurrentDate)
                }
            }
        } else {
            if let selectedDay = selectedDay {
                if let newSelectedDay = Calendar.current.date(byAdding: .month, value: -1, to: selectedDay) {
                    self.selectedDay = newSelectedDay
                    generateDays(for: newSelectedDay)
                }
            } else {
                // 沒有選擇日期，基於 currentDate 減去一個月
                if let newCurrentDate = Calendar.current.date(byAdding: .month, value: -1, to: currentDate) {
                    self.currentDate = newCurrentDate
                    generateDays(for: newCurrentDate)
                }
            }
        }
    }
    
    func nextPeriod() {
        if isWeekView {
            if let selectedDay = selectedDay {
                // 有選擇日期，基於 selectedDay 增加一週
                if let newSelectedDay = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: selectedDay) {
                    self.selectedDay = newSelectedDay
                    generateDays(for: newSelectedDay)
                }
            } else {
                // 沒有選擇日期，基於 currentDate 增加一週
                if let newCurrentDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: currentDate) {
                    self.currentDate = newCurrentDate
                    generateDays(for: newCurrentDate)
                }
            }
        } else {
            if let selectedDay = selectedDay {
                // 有選擇日期，基於 selectedDay 增加一個月
                if let newSelectedDay = Calendar.current.date(byAdding: .month, value: 1, to: selectedDay) {
                    self.selectedDay = newSelectedDay
                    generateDays(for: newSelectedDay)
                }
            } else {
                // 沒有選擇日期，基於 currentDate 增加一個月
                if let newCurrentDate = Calendar.current.date(byAdding: .month, value: 1, to: currentDate) {
                    self.currentDate = newCurrentDate
                    generateDays(for: newCurrentDate)
                }
            }
        }
    }
    
    func formattedMonthAndYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        if isWeekView {
            // 週視圖顯示當週的日期範圍
            let calendar = Calendar.current
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
            let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek)!
            formatter.dateFormat = "MMM d"
            let startString = formatter.string(from: startOfWeek)
            let endString = formatter.string(from: endOfWeek)
            return "\(startString) - \(endString)"
        } else {
            // 月視圖顯示月份和年份
            formatter.dateFormat = "yyyy MMM"
            return formatter.string(from: date)
        }
    }
    
    private func fetchAppointments() {
        appointmentListener?.remove()
        
        appointmentListener = AppointmentFirebaseService.shared.fetchConfirmedAppointments(
            forTeacherID: (userRole == "teacher") ? userID : nil,
            studentID: (userRole == "student") ? userID : nil
        ) { result in
            switch result {
            case .success(let fetchedAppointments):
                DispatchQueue.main.async {
                    self.appointments = fetchedAppointments
                    self.mapAppointmentsToDates()
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
                duplicateAppointments.append(appointment)
            } else {
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
        
        if !duplicateAppointments.isEmpty {
            print("重複的預約: \(duplicateAppointments.map { $0.id })")
        }
        
        for (date, appointments) in CalendarService.shared.activitiesByDate {
            // 如果日期的所有課程都被取消，則從 internalDateColors 中移除該日期
            let hasConfirmedAppointments = appointments.contains { $0.status.lowercased() == "confirmed" }
            
            if hasConfirmedAppointments {
                // 日期下有已確認的課程，顯示點點
                internalDateColors[date] = .mainOrange
            } else {
                // 沒有確認的課程，移除該日期的點點
                internalDateColors.removeValue(forKey: date)
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

struct NotePopupViewWrapper: UIViewRepresentable {
    var onSave: (String) -> Void
    var onCancel: () -> Void
    
    func makeUIView(context: Context) -> NotePopupView {
        let notePopupView = NotePopupView()
        notePopupView.onSave = onSave
        notePopupView.onCancel = onCancel
        return notePopupView
    }
    
    func updateUIView(_ uiView: NotePopupView, context: Context) {
        // 更新邏輯
    }
}
