//
//  ColorPickerCalendarView.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/19.
//

import SwiftUI

struct ColorPickerCalendarView: View {
    @State private var dateColors: [Date: Color] = [:]
    @State private var selectedDay: Date? = nil
    @State private var showColorPicker: Bool = false
    @State private var appointments: [Appointment] = []
    @State private var availableColors: [Color] = []
    @State private var activitiesByDate: [Date: [Appointment]] = [:]
    @State private var timeSlots: [AvailableTimeSlot] = []

    var body: some View {
        BaseCalendarView(
            externalDateColors: Binding(
                            get: { dateColors },             // 獲取非可選的 @State
                            set: { dateColors = $0 ?? [:] }  // 處理可能的 nil，設置為空字典
                        ),
//            selectedDay: $selectedDay,
//            appointments: appointments,
//            activitiesByDate: activitiesByDate,
            onDayTap: { day in
                selectedDay = day
            },
            onDayLongPress: { day in
                selectedDay = day
                showColorPicker = true
            }
        )
        .sheet(isPresented: $showColorPicker) {
                    if let selectedDay = selectedDay {
                        let existingColor = dateColors[selectedDay]
                        ColorPickerView(
                            selectedDate: selectedDay,
                            existingColor: existingColor,
                            availableColors: availableColors,
                            onSelectColor: { color in
                                dateColors[selectedDay] = color
                                saveDateColorToFirebase(date: selectedDay, color: color)
                                selectNextDay()  // 選擇顏色後自動跳到下一天
                            }
                        )
                        .presentationDetents([.fraction(0.25)])
                    }
                }
        .onAppear {
            fetchDateColors()
            fetchTimeSlots()
            fetchAppointments()
        }
    }

    private func fetchDateColors() {
        let teacherRef = UserFirebaseService.shared.db.collection("teachers").document(teacherID)
        
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
    
    private func selectNextDay() {
            guard let currentDay = selectedDay else { return }
            
            // 使用 Calendar 計算下一天的日期
            if let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: currentDay) {
                selectedDay = nextDay
            }
        }

    private func fetchTimeSlots() {
        UserFirebaseService.shared.fetchTimeSlots(forTeacher: teacherID) { result in
            switch result {
            case .success(let fetchedTimeSlots):
                DispatchQueue.main.async {
                    self.timeSlots = fetchedTimeSlots
                    self.extractAvailableColors() // 這裡調用 extractAvailableColors() 方法來從時段中提取顏色
                }
            case .failure(let error):
                print("獲取時段時出錯：\(error)")
            }
        }
    }
    
    private func extractAvailableColors() {
            // 假設每個 timeSlot 有一個 colorHex 屬性來表示顏色
            let colorHexes = Set(timeSlots.map { $0.colorHex })  // 使用 Set 確保顏色唯一
            self.availableColors = colorHexes.map { Color(hex: $0) }
        }

    private func fetchAppointments() {
        // Implement your method to fetch appointments
        AppointmentFirebaseService.shared.fetchConfirmedAppointments(forTeacherID: teacherID) { result in
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
        // Implement your method to save the selected color to Firebase
        UserFirebaseService.shared.saveDateColorToFirebase(date: date, color: color, teacherID: teacherID)
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
