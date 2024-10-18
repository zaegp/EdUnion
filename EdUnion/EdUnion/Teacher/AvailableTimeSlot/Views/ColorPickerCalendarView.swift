//
//  ColorPickerCalendarView.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/19.
//

import SwiftUI
import TipKit

struct CalendarTip: Tip {
    var title: Text {
        Text("設置可選時段")
    }
    
    var message: Text? {
        Text("長按日期一次為多個日期設置可選時段")
    }
    
    var image: Image? {
        Image(systemName: "hand.tap.fill")
    }
}

struct ColorPickerCalendarView: View {
    @State private var dateColors: [Date: Color] = [:]
    @State private var selectedDay: Date? = nil
    @State private var showColorPicker: Bool = false
    @State private var appointments: [Appointment] = []
    @State private var availableColors: [Color] = []
    @State private var activitiesByDate: [Date: [Appointment]] = [:]
    @State private var timeSlots: [AvailableTimeSlot] = []
    let userID = UserSession.shared.currentUserID
    
    let calendarTip = CalendarTip()
    
    var body: some View {
        VStack {
            Spacer()
            
            TipView(calendarTip)
                .tipBackground(.myCell)
                .tint(.myBlack)
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
            BaseCalendarView(
                externalDateColors: Binding(
                    get: { dateColors },
                    set: { dateColors = $0 ?? [:] }
                ), viewModel: BaseCalendarViewModel(),
                //            selectedDay: $selectedDay,
                //            appointments: appointments,
                //            activitiesByDate: activitiesByDate,
                onDayTap: { day in
                    self.selectedDay = day
                },
                onDayLongPress: { day in
                    selectedDay = day
                    showColorPicker = true
                    
                    calendarTip.invalidate(reason: .actionPerformed)
                }
            )
            .sheet(isPresented: Binding<Bool>(
                get: { selectedDay != nil && showColorPicker },  
                set: { showColorPicker = $0 }
            )) {
                Group {
                    if let selectedDay = selectedDay {
                        let existingColor = dateColors[selectedDay]
                        ColorPickerView(
                            selectedDate: selectedDay,
                            existingColor: existingColor,
                            availableColors: availableColors,
                            onSelectColor: { color in
                                dateColors[selectedDay] = color
                                saveDateColorToFirebase(date: selectedDay, color: color)
                                selectNextDay(onDayTap: { nextDay in
                                    self.selectedDay = nextDay
                                })
                            }
                        )
                    }
                }
                .presentationDetents([.fraction(0.25)])
            }
            .onAppear {
                fetchDateColors()
                fetchTimeSlots()
                fetchAppointments()
            }
            .task {
                try? Tips.resetDatastore()
                        try? await Tips.configure()
                    }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.myBackground)
        .edgesIgnoringSafeArea(.all)
    }
    
    private func fetchDateColors() {
        let teacherRef = UserFirebaseService.shared.db.collection("teachers").document(userID ?? "")
        
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
    
    private func selectNextDay(onDayTap: ((Date) -> Void)?) {
        guard let currentDay = selectedDay else { return }
        
        if let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: currentDay) {
            DispatchQueue.main.async {
                self.selectedDay = nextDay
                
                if let onDayTap = onDayTap {
                    onDayTap(nextDay)
                }
            }
        }
    }
    
    private func fetchTimeSlots() {
        UserFirebaseService.shared.fetchTimeSlots(forTeacher: userID ?? "") { result in
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
    
    private func fetchAppointments() {
        AppointmentFirebaseService.shared.fetchConfirmedAppointments(forTeacherID: userID) { result in
            switch result {
            case .success(let fetchedAppointments):
                DispatchQueue.main.async {
                    self.appointments = fetchedAppointments
                    self.mapAppointmentsToDates()
                }
            case .failure(let error):
                print("Error fetching appointments: \(error)")
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
    
    private func saveDateColorToFirebase(date: Date, color: Color) {
        UserFirebaseService.shared.saveDateColorToFirebase(date: date, color: color, teacherID: userID ?? "")
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter
    }()
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

#Preview {
    ColorPickerCalendarView()
}

let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
}()
