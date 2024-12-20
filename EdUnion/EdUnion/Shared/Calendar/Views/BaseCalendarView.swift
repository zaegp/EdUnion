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
    
    private var foregroundColor: Color {
        if isToday && isSelected {
            return Color(UIColor.systemBackground)
        } else if isSelected {
            return Color(UIColor.label)
        } else if isToday {
            return Color.mainOrange
        } else {
            return Color(UIColor.systemBackground)
        }
    }
    
    private var isToday: Bool {
        guard let day = day else { return false }
        return Calendar.current.isDateInToday(day)
    }
    
    private var isPastDate: Bool {
        guard let day = day else { return false }
        return Calendar.current.isDateInYesterdayOrEarlier(day)
    }
    
    var body: some View {
        VStack(spacing: 5) {
            if let day = day {
                Text(day.formatted(.dateTime.day()))
                    .fontWeight(.bold)
                    .foregroundColor(foregroundColor)
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
                
                Circle()
                    .fill(color != .clear ? color : Color.clear)
                    .frame(width: 8, height: 8)
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
                            if userRole == UserRole.teacher.rawValue {
                                Text(viewModel.participantNames[appointment.studentID] ?? "")
                                    .onAppear {
                                        if viewModel.participantNames[appointment.studentID] == nil {
                                            viewModel.fetchUserData(from: Constants.studentsCollection, userID: appointment.studentID, as: Student.self)
                                        }
                                    }
                                    .font(.headline)
                                    .foregroundColor(Color(UIColor.myDarkGray))
                            } else {
                                Text(viewModel.participantNames[appointment.teacherID] ?? "")
                                    .onAppear {
                                        if viewModel.participantNames[appointment.studentID] == nil {
                                            viewModel.fetchUserData(from: Constants.teachersCollection, userID: appointment.teacherID, as: Teacher.self)
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
            if userRole == UserRole.student.rawValue {
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
            
            if userRole == UserRole.student.rawValue {
                Button(action: onCancel) {
                    Text("取消預約")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.mainOrange)
                        .cornerRadius(10)
                }
            } else {
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
    @ObservedObject var viewModel: BaseCalendarViewModel
    @State private var isShowingDetail = false
    @State private var selectedAppointment: Appointment?
    @State private var appointmentListener: ListenerRegistration?
    @State private var isShowingCard = false
    let userID = UserSession.shared.unwrappedUserID
    let userRole = UserDefaults.standard.string(forKey: "userRole") ?? "teacher"
    
    var dateColors: [Date: Color] {
        externalDateColors ?? viewModel.internalDateColors
    }
    
    @State private var selectedDay: Date? = Calendar.current.startOfDay(for: Date())
    
    @State private var appointments: [Appointment] = []
    
    var onDayTap: ((Date) -> Void)?
    var onDayLongPress: ((Date) -> Void)?
    
    @State private var currentDate = Date()
    let daysOfWeek = Calendar.current.shortWeekdaySymbols
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    @State private var selectedStudentID: String = ""
    @State private var isShowingNotePopup = false
    @State private var noteText = ""
    
    var body: some View {
        let colors = dateColors
        ZStack {
            VStack {
                VStack {
                    HeaderView(
                        formattedMonthAndYear: TimeService.formattedMonthAndYear(for: selectedDay ?? currentDate, isWeekView: viewModel.isWeekView),
                        previousAction: previousPeriod,
                        nextAction: nextPeriod
                    )
                    .background(Color.myDarkGray)
                    .cornerRadius(30)
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
                        ForEach(viewModel.days) { calendarDay in
                            if let day = calendarDay.date {
                                let isCurrentMonth = Calendar.current.isDate(day, equalTo: currentDate, toGranularity: .month)
                                
                                CalendarDayView(
                                    day: day,
                                    isSelected: selectedDay != nil && Calendar.current.isDate(selectedDay!, inSameDayAs: day),
                                    isCurrentMonth: isCurrentMonth,
                                    color: dateColors[day] ?? .clear
                                )
                                .onTapGesture {
                                    onDayTap?(day)
                                    
                                    if selectedDay == day {
                                        selectedDay = nil
                                    } else {
                                        selectedDay = day
                                    }
                                }
                                .onLongPressGesture {
                                    onDayLongPress?(day)
                                }
                            } else {
                                CalendarDayView(day: nil, isSelected: false, isCurrentMonth: false, color: .clear)
                            }
                        }
                    }
                    .frame(height: viewModel.isWeekView ? 80 : nil)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.isWeekView)
                    .gesture(dragHandler())
                    .onAppear {
                        viewModel.generateDays(for: currentDate)
                        viewModel.fetchAppointments(forUserID: userID, userRole: userRole)
                        viewModel.fetchStudents(for: userID)
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
                        },
                        viewModel: viewModel
                    )
                    .onAppear {
                        viewModel.loadAndSortActivities(for: activities)
                    }
                    .onChange(of: selectedDay) {
                        let newActivities = viewModel.activitiesByDate[Calendar.current.startOfDay(for: selectedDay)]
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
                            participantName: userRole == UserRole.student.rawValue
                            ? (viewModel.participantNames[appointment.teacherID] ?? "")
                            : (viewModel.participantNames[appointment.studentID] ?? ""),
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
                            viewModel.saveNoteText(text, for: selectedStudentID, teacherID: userID) { result in
                                switch result {
                                case .success:
                                    print("備註已保存")
                                case .failure(let error):
                                    print("保存備註失敗: \(error.localizedDescription)")
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
    
    func adjustPeriod(by value: Int) {
        let component: Calendar.Component = viewModel.isWeekView ? .weekOfYear : .month
        
        if let selectedDay = selectedDay {
            if let newSelectedDay = Calendar.current.date(byAdding: component, value: value, to: selectedDay) {
                self.selectedDay = newSelectedDay
                viewModel.generateDays(for: newSelectedDay)
            }
        } else {
            if let newCurrentDate = Calendar.current.date(byAdding: component, value: value, to: currentDate) {
                self.currentDate = newCurrentDate
                viewModel.generateDays(for: newCurrentDate)
            }
        }
    }
    
    func previousPeriod() {
        adjustPeriod(by: -1)
    }
    
    func nextPeriod() {
        adjustPeriod(by: 1)
    }
}

extension BaseCalendarView {
    private func dragHandler() -> some Gesture {
            DragGesture()
                .onEnded(handleDragEnded)
        }
        
        private func handleDragEnded(_ value: DragGesture.Value) {
            let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
            feedbackGenerator.prepare()
            
            if abs(value.translation.width) > abs(value.translation.height) {
                handleHorizontalDrag(value.translation.width)
            } else {
                handleVerticalDrag(value.translation.height)
            }
            
            feedbackGenerator.impactOccurred()
        }
    
    private func handleHorizontalDrag(_ width: CGFloat) {
        if width < 0 {
            nextPeriod()
        } else {
            previousPeriod()
        }
    }
    
    private func handleVerticalDrag(_ height: CGFloat) {
        withAnimation {
            if height < 0 && !viewModel.isWeekView {
                viewModel.isWeekView.toggle()
                viewModel.generateDays(for: selectedDay ?? currentDate)
            } else if height > 0 && viewModel.isWeekView {
                viewModel.isWeekView.toggle()
                viewModel.generateDays(for: selectedDay ?? currentDate)
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
        
        viewModel.generateDays(for: selectedDay ?? currentDate)
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
