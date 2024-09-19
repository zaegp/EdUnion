//
//  ColorPickerCalendarView.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/19.
//

import SwiftUI

struct CalendarViewWithColorPicker: View {
    @State private var days: [Date?] = []
    @State private var selectedDay: Date? = nil
    @State private var showColorPicker: Bool = false
    @State private var availableColors: [Color] = []
    @State private var timeSlots: [AvailableTimeSlot] = []
    @State private var dateColors: [Date: Color] = [:] // 存储每个日期对应的颜色
    
    var teacherID: String

    var body: some View {
        BaseCalendarView(
            onDayTap: { day in
                selectedDay = day
            },
            onDayLongPress: { day in
                selectedDay = day
                showColorPicker = true
            }
        )
        .onAppear {
            fetchDateColors() // 视图加载时从 Firebase 获取颜色
            fetchTimeSlots()
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
                        UserFirebaseService.shared.saveDateColorToFirebase(date: selectedDay, color: color, teacherID: teacherID)
                        selectNextDay()
                    }
                )
                .presentationDetents([.fraction(0.25)])
            }
        }
    }

    // 获取下一个日期
    private func selectNextDay() {
        guard let currentDay = selectedDay else { return }
        
        if let nextDayIndex = days.firstIndex(of: currentDay)?.advanced(by: 1), nextDayIndex < days.count {
            selectedDay = days[nextDayIndex]
        } else {
            selectedDay = nil
        }
    }

    private func fetchTimeSlots() {
        UserFirebaseService.shared.fetchTimeSlots(forTeacher: teacherID) { result in
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
    
    // 从 Firebase 获取日期的颜色
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
    CalendarViewWithColorPicker(teacherID: teacherID)
}

let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
}()
