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

struct HeaderView: View {
    let formattedMonthAndYear: String
    let previousAction: () -> Void
    let nextAction: () -> Void
    
    var body: some View {
        HStack {
            Button(action: previousAction) {
                Image(systemName: "chevron.left")
                    .foregroundColor(Color(UIColor.systemBackground))
            }
            Spacer()
            Text(formattedMonthAndYear)
                .font(.headline)
                .foregroundColor(Color(UIColor.systemBackground))
            Spacer()
            Button(action: nextAction) {
                Image(systemName: "chevron.right")
                    .foregroundColor(Color(UIColor.systemBackground))
            }
        }
        .padding()
    }
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

struct AppointmentsListView: View {
    let appointments: [Appointment]
    let userRole: String
    let onAppointmentTap: (Appointment) -> Void
    @ObservedObject var viewModel = BaseCalendarViewModel()
    
    var body: some View {
        List {
            ForEach(appointments) { appointment in
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
                .padding(.vertical, 5)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.myBackground)
                .frame(height: 40)
                .onTapGesture {
                    onAppointmentTap(appointment)
                }
            }
        }
        .listStyle(PlainListStyle())
    }
}

struct AppointmentDetailCardView: View {
    let appointment: Appointment
    let userRole: String
    let participantName: String
    let onCancel: () -> Void
    let onShowNote: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Text(appointment.date)
                .font(.headline)
            if userRole == "student" {
                Text(participantName)
                    .font(.title)
                    .fontWeight(.semibold)
            } else {
                Text(participantName)
                    .font(.title)
                    .fontWeight(.semibold)
            }
            Text(TimeService.convertCourseTimeToDisplay(from: appointment.times))
                .font(.subheadline)
            
            if userRole == "student" {
                Button(action: onCancel) {
                    Text("取消預約")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.mainOrange)
                        .cornerRadius(10)
                }
            } else if userRole == "teacher" {
                Button(action: onShowNote) {
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
    }
}

struct BaseCalendarView: View {
    @Binding var externalDateColors: [Date: Color]?
    //    @State private var internalDateColors: [Date: Color] = [:]
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
    
    //    var dateColors: [Date: Color] {
    //        get {
    //            externalDateColors ?? internalDateColors
    //        }
    //        set {
    //            if externalDateColors != nil {
    //                externalDateColors = newValue
    //            } else {
    //                internalDateColors = newValue
    //            }
    //        }
    //    }
    
    var dateColors: [Date: Color] {
        externalDateColors ?? viewModel.internalDateColors
    }
    
    //    @State private var selectedDay: Date? = nil
    @State private var selectedDay: Date? = Calendar.current.startOfDay(for: Date())
    
    @State private var appointments: [Appointment] = []
    
    var onDayTap: ((Date) -> Void)?
    var onDayLongPress: ((Date) -> Void)?
    
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
                    HeaderView(
                        formattedMonthAndYear: formattedMonthAndYear(selectedDay ?? currentDate),
                        previousAction: previousPeriod,
                        nextAction: nextPeriod
                    )
                    .background(Color.myDarkGray)
                    .cornerRadius(30)
                    .padding()
                    //                    HStack {
                    //                        Button(action: { previousPeriod() }) {
                    //                            Image(systemName: "chevron.left")
                    //                                .foregroundColor(Color(UIColor.systemBackground))
                    //                        }
                    //                        Spacer()
                    //                        Text(formattedMonthAndYear(selectedDay ?? currentDate))
                    //                            .font(.headline)
                    //                            .foregroundColor(Color(UIColor.systemBackground))
                    //                        Spacer()
                    //                        Button(action: { nextPeriod() }) {
                    //                            Image(systemName: "chevron.right")
                    //                                .foregroundColor(Color(UIColor.systemBackground))
                    //                        }
                    //                    }
                    //                    .padding()
                    
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
                            viewModel.fetchAppointments(forUserID: userID ?? "", userRole: userRole)
                            viewModel.fetchStudents(for: userID ?? "")
                            isDataLoaded = true
                        }
                    }
                }
                .padding()
                .background(Color.myDarkGray)
                .cornerRadius(30)
                .padding()
                
                Spacer()
                
                if let selectedDay = selectedDay,
                   let activities = viewModel.activitiesByDate[Calendar.current.startOfDay(for: selectedDay)] {
                    AppointmentsListView(
                        appointments: viewModel.sortedActivities,
                        userRole: userRole,
                        onAppointmentTap: { appointment in
                            selectedAppointment = appointment
                            isShowingCard = true
                        }, viewModel: viewModel
                    )
                    .onAppear {
                        viewModel.loadAndSortActivities(for: activities)
                    }
                    .onChange(of: selectedDay) { newDay in
                        let newActivities = viewModel.activitiesByDate[Calendar.current.startOfDay(for: newDay)]
                        if let newActivities = newActivities {
                            viewModel.loadAndSortActivities(for: newActivities)
                        }
                    }
                    .padding(.bottom, 80)
                } else {
                    VStack {
                        Spacer()
                        Text("沒有課程")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .padding()
                        Spacer()
                    }
                    .padding(.bottom, 80)
                }
            }
            .background(Color.myBackground)
            
            if isShowingCard, let appointment = selectedAppointment {
                withAnimation(.easeInOut) {
                    ZStack {
                        Color.primary.opacity(0.2)
                            .edgesIgnoringSafeArea(.all)
                            .onTapGesture {
                                isShowingCard = false
                            }
                        
                        AppointmentDetailCardView(
                            appointment: appointment,
                            userRole: userRole,
                            participantName: userRole == "student"
                            ? (viewModel.participantNames[appointment.teacherID] ?? "Unknown")
                            : (viewModel.participantNames[appointment.studentID] ?? "Unknown"),
                            onCancel: {
                                if let appointmentID = appointment.id {
                                    viewModel.cancelAppointment(appointmentID: appointmentID) { result in
                                        switch result {
                                        case .success:
                                            print("取消成功")
                                            isShowingCard = false
                                        case .failure(let error):
                                            print("取消失敗: \(error.localizedDescription)")
                                        }
                                    }
                                }
                            },
                            onShowNote: {
                                selectedStudentID = appointment.studentID
                                isShowingNotePopup = true
                            }
                        )
                    }
                    .transition(.opacity)
                }
            }
        }
        .overlay(
            ZStack {
                if isShowingNotePopup {
                    NotePopupViewWrapper(
                        noteText: viewModel.studentsNotes[selectedStudentID] ?? "",
                        onSave: { text in
                            viewModel.saveNoteText(text, for: selectedStudentID, teacherID: userID ?? "") { result in
                                switch result {
                                case .success:
                                    print("备注已保存")
                                case .failure(let error):
                                    print("保存备注失败: \(error.localizedDescription)")
                                }
                            }
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
            guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: referenceDate)) else {
                return
            }
            for i in 0..<7 {
                if let date = calendar.date(byAdding: .day, value: i, to: startOfWeek) {
                    days.append(CalendarDay(date: date))
                }
            }
        } else {
            guard let range = calendar.range(of: .day, in: .month, for: referenceDate) else { return }
            let numDays = range.count
            
            guard let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: referenceDate)) else { return }
            let weekdayOfFirstDay = calendar.component(.weekday, from: firstDayOfMonth)
            
            let leadingEmptyDays = (weekdayOfFirstDay + 6) % 7
            
            for _ in 0..<leadingEmptyDays {
                days.append(CalendarDay(date: nil))
            }
            
            for day in 1...numDays {
                if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                    days.append(CalendarDay(date: date))
                }
            }
        }
        
        for day in days {
            if let day = day.date {
                print(day)
            } else {
                print("nil")
            }
        }
    }
    
    func updateAppointmentsForDay(_ day: Date) {
        let startOfDay = Calendar.current.startOfDay(for: day)
        
        if let appointmentsForDay = CalendarService.shared.activitiesByDate[startOfDay] {
            let hasConfirmedAppointments = appointmentsForDay.contains { $0.status.lowercased() == "confirmed" }
            
            if !hasConfirmedAppointments {
                viewModel.internalDateColors.removeValue(forKey: startOfDay)
            }
        } else {
            viewModel.internalDateColors.removeValue(forKey: startOfDay)
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
            
            generateDays(for: selectedDay ?? currentDate)
        }
    }
    
    private func setupView() {
        generateDays(for: currentDate)
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
                if let newSelectedDay = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: selectedDay) {
                    self.selectedDay = newSelectedDay
                    generateDays(for: newSelectedDay)
                }
            } else {
                if let newCurrentDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: currentDate) {
                    self.currentDate = newCurrentDate
                    generateDays(for: newCurrentDate)
                }
            }
        } else {
            if let selectedDay = selectedDay {
                if let newSelectedDay = Calendar.current.date(byAdding: .month, value: 1, to: selectedDay) {
                    self.selectedDay = newSelectedDay
                    generateDays(for: newSelectedDay)
                }
            } else {
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
            let calendar = Calendar.current
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
            let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek)!
            formatter.dateFormat = "MMM d"
            let startString = formatter.string(from: startOfWeek)
            let endString = formatter.string(from: endOfWeek)
            return "\(startString) - \(endString)"
        } else {
            formatter.dateFormat = "yyyy MMM"
            return formatter.string(from: date)
        }
    }
}

struct NotePopupViewWrapper: UIViewRepresentable {
    var noteText: String?
    var onSave: (String) -> Void
    var onCancel: () -> Void
    
    func makeUIView(context: Context) -> NotePopupView {
        let notePopupView = NotePopupView()
        notePopupView.onSave = onSave
        notePopupView.onCancel = onCancel
        notePopupView.setExistingNoteText(noteText ?? "")
        return notePopupView
    }
    
    func updateUIView(_ uiView: NotePopupView, context: Context) {
    }
}
