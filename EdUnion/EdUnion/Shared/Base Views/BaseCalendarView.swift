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
    
    @State private var appointments: [Appointment] = []
    /*@State private var activitiesByDate: [Date: [Appointment]] = [:]*/
    
    var onDayTap: ((Date) -> Void)? = nil
    var onDayLongPress: ((Date) -> Void)? = nil
    
    @State private var currentDate = Date()
    let daysOfWeek = Calendar.current.shortWeekdaySymbols
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    @State private var days: [Date?] = []
    //    @State private var leftIsActive = false
    //    @State private var rightIsActive = false
    
    var body: some View {
        let colors = dateColors
        VStack {
            HStack {
                Button(action: { previousPeriod() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Color(.backButton))
                    //                        .symbolEffect(.bounce.down.byLayer, value: leftIsActive)
                    //                        .onTapGesture {
                    //                            leftIsActive.toggle()
                    //                        }
                }
                Spacer()
                Text(formattedMonthAndYear(currentDate))
                    .font(.headline)
                Spacer()
                Button(action: { nextPeriod() }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color(.backButton))
                    //                        .symbolEffect(.bounce.down.byLayer, value: rightIsActive)
                    //                        .onTapGesture {
                    //                            rightIsActive.toggle()
                    //                        }
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
                            print("點擊了日期：\(day)")
                            toggleSingleSelection(for: day)
                            onDayTap?(day)
                        }
                        .onLongPressGesture {
                            onDayLongPress?(day)
                            //                            selectedDay = day
                        }
                    } else {
                        CalendarDayView(day: nil, isSelected: false, isCurrentMonth: false, color: .clear)
                    }
                }
                
            }
            .gesture(
                DragGesture()
                    .onEnded { value in
                        let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
                        feedbackGenerator.prepare()
                        
                        if value.translation.width < 0 {
                            nextPeriod()
                            feedbackGenerator.impactOccurred()
                        } else if value.translation.width > 0 {
                            previousPeriod()
                            feedbackGenerator.impactOccurred()
                        }
                    }
            )
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
                                        // 使用通用方法查詢學生或教師的資料
                                        Text(viewModel.participantNames[appointment.studentID] ?? "Unknown")
                                            .onAppear {
                                                if viewModel.participantNames[appointment.studentID] == nil {
                                                                            // 從 UserDefaults 獲取 userRole
                                                                            let userRole = UserDefaults.standard.string(forKey: "userRole") ?? ""

                                                                            if userRole == "student" {
                                                                                // 如果角色是學生，則查詢學生資料
                                                                                viewModel.fetchUserData(from: "students", userID: appointment.studentID, as: Student.self)
                                                                            } else if userRole == "teacher" {
                                                                                // 如果角色是老師，則查詢教師資料
                                                                                viewModel.fetchUserData(from: "teachers", userID: appointment.teacherID, as: Teacher.self)
                                                                            }
                                                                        }
                                            }
                                            .font(.subheadline)
                                            .foregroundColor(.gray)

                                        Spacer()

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
                            DetailView(appointment: selectedAppointment)
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



