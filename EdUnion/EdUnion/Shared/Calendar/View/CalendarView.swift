//
//  CalendarView.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/13.
//

import SwiftUI

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
            Text("選擇顏色")
                .font(.headline)
                .padding()
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(availableColors, id: \.self) { color in
                        Button(action: {
                            self.selectedColor = color
                            onSelectColor(color)
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
    
    @State private var appointments: [Appointment] = []
    @State private var activitiesByDate: [Date: [Appointment]] = [:]
    
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
                    if let day = day {
                        let isCurrentMonth = Calendar.current.isDate(day, equalTo: currentDate, toGranularity: .month)
                        
                        CalendarDayView(
                            day: day,
                            isSelected: selectedDay == day,
                            isCurrentMonth: isCurrentMonth,
                            color: dateColors[day] ?? .clear
                        )
                        .onTapGesture {
                            toggleSingleSelection(for: day)
                        }
                        .onLongPressGesture {
                            selectedDay = day
                            showColorPicker = true
                        }
                    } else {
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
                fetchAppointments()
            }
            
            Spacer()
            
            if let selectedDay = selectedDay, let activities = activitiesByDate[Calendar.current.startOfDay(for: selectedDay)] {
                ZStack {
                    // 設置整個背景為白色
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
                                .background(Color(uiColor: .background))
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
        .sheet(isPresented: $showColorPicker) {
            if let selectedDay = selectedDay {
                let existingColor = dateColors[selectedDay]
                ColorPickerView(
                    selectedDate: selectedDay,
                    existingColor: existingColor,
                    availableColors: availableColors,
                    onSelectColor: { color in
                        dateColors[selectedDay] = color
                        FirebaseService.shared.saveDateColorToFirebase(date: selectedDay, color: color, teacherID: teacherID)
                        selectNextDay()
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
            selectedDay = days[nextDayIndex]
        } else {
            selectedDay = nil
        }
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
    
    private func fetchAppointments() {
        FirebaseService.shared.fetchAppointments(forTeacherID: teacherID) { result in
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
        activitiesByDate.removeAll()
        
        for appointment in appointments {
            if let date = dateFormatter.date(from: appointment.date) {
                let startOfDay = Calendar.current.startOfDay(for: date)
                if activitiesByDate[startOfDay] != nil {
                    activitiesByDate[startOfDay]?.append(appointment)
                } else {
                    activitiesByDate[startOfDay] = [appointment]
                }
            }
        }
    }
    
    private func fetchTimeSlots() {
        FirebaseService.shared.fetchTimeSlots(forTeacher: teacherID) { result in
            switch result {
            case .success(let fetchedTimeSlots):
                DispatchQueue.main.async {
                    self.timeSlots = fetchedTimeSlots
                    self.extractAvailableColors()
                }
            case .failure(let error):
                print("獲取時段時出錯：\(error)")
            }
        }
    }
    
    private func extractAvailableColors() {
        let colorHexes = Set(timeSlots.map { $0.colorHex })
        self.availableColors = colorHexes.map { Color(hex: $0) }
    }
    
    private func fetchDateColors() {
        let teacherRef = FirebaseService.shared.db.collection("teachers").document(teacherID)
        
        teacherRef.getDocument { (documentSnapshot, error) in
            if let error = error {
                print("獲取日期顏色時出錯：\(error)")
            } else if let document = documentSnapshot, document.exists {
                if let data = document.data(), let selectedTimeSlots = data["selectedTimeSlots"] as? [String: String] {
                    for (dateString, colorHex) in selectedTimeSlots {
                        if let date = dateFormatter.date(from: dateString) {
                            self.dateColors[date] = Color(hex: colorHex)
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
