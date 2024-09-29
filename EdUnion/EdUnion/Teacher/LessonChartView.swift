//////
//////  LessonChartView.swift
//////  EdUnion
//////
//////  Created by Rowan Su on 2024/9/29.
//////
////
//import SwiftUI
//import Charts
//import FirebaseFirestore
//
//struct LessonChartView: View {
//    @State private var appointments: [Appointment] = []
//    @State private var lessonsPerDay: [String: Int] = [:]
//    @State private var selectedTimeFrame: TimeFrame = .daily
//    private let firestore = Firestore.firestore()
//    let teacherID: String
//
//    enum TimeFrame {
//        case daily, weekly, monthly
//    }
//
//    var body: some View {
//        VStack {
//            Picker("Time Frame", selection: $selectedTimeFrame) {
//                Text("Daily").tag(TimeFrame.daily)
//                Text("Weekly").tag(TimeFrame.weekly)
//                Text("Monthly").tag(TimeFrame.monthly)
//            }
//            .pickerStyle(SegmentedPickerStyle())
//            .padding()
//
//            Chart {
//                ForEach(lessonsPerDay.sorted(by: { $0.key < $1.key }), id: \.key) { date, count in
//                    BarMark(
//                        x: .value("Date", date),
//                        y: .value("Lessons", count)
//                    )
//                }
//            }
//            .frame(height: 300)
//            .padding()
//
//            Spacer()
//        }
//        .onAppear {
//            fetchAppointments()
//        }
//        .onChange(of: selectedTimeFrame) { _ in
//            updateLessonsData()
//        }
//    }
//
//    // Fetch appointments from Firestore
//    func fetchAppointments() {
//        firestore.collection("appointments")
//            .whereField("teacherID", isEqualTo: teacherID)
//            .getDocuments { (snapshot, error) in
//                if let error = error {
//                    print("Error fetching appointments: \(error.localizedDescription)")
//                    return
//                }
//
//                var fetchedAppointments: [Appointment] = []
//                for document in snapshot?.documents ?? [] {
//                    do {
//                        let appointment = try document.data(as: Appointment.self)
//                        fetchedAppointments.append(appointment)
//                    } catch {
//                        print("Error decoding appointment: \(error)")
//                    }
//                }
//
//                appointments = fetchedAppointments
//                updateLessonsData()
//            }
//    }
//
//    // Update lessonsPerDay based on selected time frame
//    func updateLessonsData() {
//        switch selectedTimeFrame {
//        case .daily:
//            lessonsPerDay = calculateLessonsPerDay()
//        case .weekly:
//            lessonsPerDay = calculateLessonsPerWeek()
//        case .monthly:
//            lessonsPerDay = calculateLessonsPerMonth()
//        }
//    }
//
//    // Calculate lessons per day
//    func calculateLessonsPerDay() -> [String: Int] {
//        var dailyLessons: [String: Int] = [:]
//
//        for appointment in appointments {
//            let date = appointment.date
//            let lessonCount = appointment.times.count
//
//            if let currentCount = dailyLessons[date] {
//                dailyLessons[date] = currentCount + lessonCount
//            } else {
//                dailyLessons[date] = lessonCount
//            }
//        }
//
//        return dailyLessons
//    }
//
//    // Calculate lessons per week
//    func calculateLessonsPerWeek() -> [String: Int] {
//        var weeklyLessons: [String: Int] = [:]
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "yyyy-MM-dd"
//
//        for appointment in appointments {
//            if let date = dateFormatter.date(from: appointment.date) {
//                let weekOfYear = Calendar.current.component(.weekOfYear, from: date)
//                let year = Calendar.current.component(.year, from: date)
//                let weekKey = "\(year)-W\(weekOfYear)"
//
//                let lessonCount = appointment.times.count
//                if let currentCount = weeklyLessons[weekKey] {
//                    weeklyLessons[weekKey] = currentCount + lessonCount
//                } else {
//                    weeklyLessons[weekKey] = lessonCount
//                }
//            }
//        }
//
//        return weeklyLessons
//    }
//
//    // Calculate lessons per month
//    func calculateLessonsPerMonth() -> [String: Int] {
//        var monthlyLessons: [String: Int] = [:]
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "yyyy-MM-dd"
//
//        for appointment in appointments {
//            if let date = dateFormatter.date(from: appointment.date) {
//                let month = Calendar.current.component(.month, from: date)
//                let year = Calendar.current.component(.year, from: date)
//                let monthKey = "\(year)-\(month)"
//
//                let lessonCount = appointment.times.count
//                if let currentCount = monthlyLessons[monthKey] {
//                    monthlyLessons[monthKey] = currentCount + lessonCount
//                } else {
//                    monthlyLessons[monthKey] = lessonCount
//                }
//            }
//        }
//
//        return monthlyLessons
//    }
//}
//
//struct LessonChartView_Previews: PreviewProvider {
//    static var previews: some View {
//        LessonChartView(teacherID: "001")
//    }
//}
//import SwiftUI
//import Charts
//import FirebaseFirestore
//
//struct LessonData: Identifiable {
//    let id = UUID()
//    let date: Date
//    let numberOfLessons: Int
//    var dateRange: String?
//}
//
////struct LessonChartView: View {
////    @State private var selectedTimePeriod = "Week"
////    @State private var lessonData: [LessonData] = []
////    @State private var appointments: [Appointment] = []
////    @State private var selectedLesson: LessonData? = nil
////    @State private var showDetails: Bool = false
////    
////    // Firestore reference
////    let firestore = Firestore.firestore()
////    let userID = UserSession.shared.currentUserID
////    
////    var body: some View {
////        VStack {
////            Picker("Time Period", selection: $selectedTimePeriod) {
////                Text("Week").tag("Week")
////                Text("Month").tag("Month")
////                Text("Year").tag("Year")
////            }
////            .pickerStyle(SegmentedPickerStyle())
////            .padding()
////            
////            Chart {
////                ForEach(lessonData) { data in
////                    BarMark(
////                        x: .value("Date", data.date),
////                        y: .value("Lessons", data.numberOfLessons)
////                    )
////                    .foregroundStyle(.orange)
////                }
////            }
////            .chartOverlay { proxy in
////                GeometryReader { geo in
////                    Rectangle()
////                        .foregroundColor(.clear)
////                        .contentShape(Rectangle())
////                        .onTapGesture { location in
////                            let xPosition = location.x - geo[proxy.plotAreaFrame].origin.x
////                            if let date: Date = proxy.value(atX: xPosition) {
////                                if let tappedLesson = lessonData.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
////                                    self.selectedLesson = tappedLesson
////                                    self.showDetails = true
////                                }
////                            }
////                        }
////                }
////            }
////            .frame(height: 300)
////            .padding()
////            .onChange(of: selectedTimePeriod) { _ in
////                updateLessonsData()
////            }
////            .onAppear {
////                generateMockAppointments() // Generate mock data
////                                updateLessonsData()
//////                fetchAppointments()
////            }
////            .alert(isPresented: $showDetails) {
////                Alert(
////                    title: Text("Lesson Details"),
////                    message: Text("Date: \(dateFormatter.string(from: selectedLesson?.date ?? Date()))\nLessons: \(selectedLesson?.numberOfLessons ?? 0)"),
////                    dismissButton: .default(Text("OK"))
////                )
////            }
////        }
////        .navigationTitle("Lessons Overview")
////    }
////    
//////    func fetchAppointments() {
//////        firestore.collection("appointments")
//////            .whereField("teacherID", isEqualTo: userID)
//////            .getDocuments { (snapshot, error) in
//////                if let error = error {
//////                    print("Error fetching appointments: \(error.localizedDescription)")
//////                    return
//////                }
//////                
//////                var fetchedAppointments: [Appointment] = []
//////                for document in snapshot?.documents ?? [] {
//////                    do {
//////                        let appointment = try document.data(as: Appointment.self)
//////                        fetchedAppointments.append(appointment)
//////                    } catch {
//////                        print("Error decoding appointment: \(error)")
//////                    }
//////                }
//////                
//////                appointments = fetchedAppointments
//////                updateLessonsData()
//////            }
//////    }
////    
////    func generateMockAppointments() {
////            let calendar = Calendar.current
////            let currentDate = Date()
////            var mockAppointments: [Appointment] = []
////            
////            // Generate 30 mock appointments over the past month
////            for dayOffset in 0..<30 {
////                if let mockDate = calendar.date(byAdding: .day, value: -dayOffset, to: currentDate) {
////                    let appointment = Appointment(
////                        id: UUID().uuidString,
////                        date: DateFormatter.localizedString(from: mockDate, dateStyle: .short, timeStyle: .none),
////                        status: "confirmed",
////                        studentID: "student_\(dayOffset)",
////                        teacherID: "test_teacher",
////                        times: ["10:00", "11:00"], // Assume each appointment has 2 lessons
////                        timestamp: mockDate
////                    )
////                    mockAppointments.append(appointment)
////                }
////            }
////            appointments = mockAppointments
////        }
////
////    
////    func updateLessonsData() {
////        let calendar = Calendar.current
////        var data: [LessonData] = []
////        
////        switch selectedTimePeriod {
////        case "Week":
////            let startOfWeek = calendar.startOfDay(for: Date())
////            for dayOffset in 0..<7 {
////                if let currentDate = calendar.date(byAdding: .day, value: -dayOffset, to: startOfWeek) {
////                    let lessons = appointments
////                        .filter { calendar.isDate($0.timestamp, inSameDayAs: currentDate) }
////                        .reduce(0) { $0 + $1.times.count }
////                    data.append(LessonData(date: currentDate, numberOfLessons: lessons))
////                }
////            }
////            
////        case "Month":
////            let startOfMonth = calendar.startOfDay(for: Date())
////            var weeklyLessons: [Int] = Array(repeating: 0, count: 4)
////            for dayOffset in 0..<30 {
////                if let currentDate = calendar.date(byAdding: .day, value: -dayOffset, to: startOfMonth) {
////                    let weekOfMonth = calendar.component(.weekOfMonth, from: currentDate) - 1
////                    let lessons = appointments
////                        .filter { calendar.isDate($0.timestamp, inSameDayAs: currentDate) }
////                        .reduce(0) { $0 + $1.times.count }
////                    if weekOfMonth < 4 {
////                        weeklyLessons[weekOfMonth] += lessons
////                    }
////                }
////            }
////            for weekIndex in 0..<4 {
////                let date = calendar.date(byAdding: .weekOfMonth, value: -weekIndex, to: startOfMonth)!
////                data.append(LessonData(date: date, numberOfLessons: weeklyLessons[weekIndex]))
////            }
////            
////        case "Year":
////            let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: Date()))!
////            var monthlyLessons: [Int] = Array(repeating: 0, count: 12)
////            for monthOffset in 0..<12 {
////                if let currentMonth = calendar.date(byAdding: .month, value: -monthOffset, to: startOfYear) {
////                    let lessons = appointments
////                        .filter { calendar.isDate($0.timestamp, equalTo: currentMonth, toGranularity: .month) }
////                        .reduce(0) { $0 + $1.times.count }
////                    monthlyLessons[monthOffset] = lessons
////                }
////            }
////            for monthIndex in 0..<12 {
////                let date = calendar.date(byAdding: .month, value: -monthIndex, to: startOfYear)!
////                data.append(LessonData(date: date, numberOfLessons: monthlyLessons[monthIndex]))
////            }
////            
////        default:
////            break
////        }
////        
////        // Sort data by date
////        lessonData = data.sorted(by: { $0.date < $1.date })
////    }
////}
//
////struct LessonChartView: View {
////    @State private var selectedTimePeriod = "Week"
////    @State private var lessonData: [LessonData] = []
////    @State private var appointments: [Appointment] = []
////    
////    @State private var selectedLesson: LessonData? = nil
////    @State private var showDetails: Bool = false
////    
////    let firestore = Firestore.firestore()
////    let userID = "test_teacher" // Replace with UserSession.shared.currentUserID for real use
////    
////    let dateFormatter: DateFormatter = {
////        let formatter = DateFormatter()
////        formatter.dateFormat = "MMM d"
////        return formatter
////    }()
////    
////    var body: some View {
////           VStack {
////               Picker("Time Period", selection: $selectedTimePeriod) {
////                   Text("Week").tag("Week")
////                   Text("Month").tag("Month")
////                   Text("Year").tag("Year")
////               }
////               .pickerStyle(SegmentedPickerStyle())
////               .padding()
////
////               Chart {
////                   ForEach(lessonData) { data in
////                       BarMark(
////                           x: .value("Date", data.date),
////                           y: .value("Lessons", data.numberOfLessons)
////                       )
////                       .foregroundStyle(.orange)
////                   }
////               }
////               .chartXAxis {
////                   AxisMarks(preset: .aligned) // 確保軸刻度對齊
////               }
////               .chartPlotStyle { plotArea in
////                   plotArea
////                       .padding(.horizontal, 10) // 調整繪圖區域的水平間距
////               }
////               .chartOverlay { proxy in
////                   GeometryReader { geo in
////                       Rectangle()
////                           .foregroundColor(.clear)
////                           .contentShape(Rectangle())
////                           .onTapGesture { location in
////                               let xPosition = location.x - geo[proxy.plotAreaFrame].origin.x
////                               if let date: Date = proxy.value(atX: xPosition) {
////                                   if let tappedLesson = lessonData.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
////                                       self.selectedLesson = tappedLesson
////                                       self.showDetails = true
////                                   }
////                               }
////                           }
////                   }
////               }
////               .chartXScale(range: .plotDimension(padding: 10))
////               .frame(height: 400)
////               .padding()
////               .onChange(of: selectedTimePeriod) { _ in
////                   updateLessonsData()
////               }
////               .onAppear {
////                   generateMockAppointments() // Generate mock data
////                   updateLessonsData()
////               }
////               .alert(isPresented: $showDetails) {
////                   Alert(
////                       title: Text("Lesson Details"),
////                       message: Text(generateDetailsMessage(for: selectedLesson)),
////                       dismissButton: .default(Text("OK"))
////                   )
////               }
////           }
////           .navigationTitle("Lessons Overview")
////       }
////    
////    // Generate mock appointment data
////    func generateMockAppointments() {
////        let calendar = Calendar.current
////        let currentDate = Date()
////        var mockAppointments: [Appointment] = []
////        
////        // Generate 30 mock appointments over the past month
////        for dayOffset in 0..<30 {
////            if let mockDate = calendar.date(byAdding: .day, value: -dayOffset, to: currentDate) {
////                let appointment = Appointment(
////                    id: UUID().uuidString,
////                    date: DateFormatter.localizedString(from: mockDate, dateStyle: .short, timeStyle: .none),
////                    status: "confirmed",
////                    studentID: "student_\(dayOffset)",
////                    teacherID: "test_teacher",
////                    times: ["10:00", "11:00"], // Assume each appointment has 2 lessons
////                    timestamp: mockDate
////                )
////                mockAppointments.append(appointment)
////            }
////        }
////        appointments = mockAppointments
////    }
////    
////    // Update chart data based on the selected time period
////    func updateLessonsData() {
////        let calendar = Calendar.current
////        var data: [LessonData] = []
////        
////        switch selectedTimePeriod {
////        case "Week":
////            let startOfWeek = calendar.startOfDay(for: Date())
////            for dayOffset in 0..<7 {
////                if let currentDate = calendar.date(byAdding: .day, value: -dayOffset, to: startOfWeek) {
////                    let lessons = appointments
////                        .filter { calendar.isDate($0.timestamp, inSameDayAs: currentDate) }
////                        .reduce(0) { $0 + $1.times.count }
////                    data.append(LessonData(date: currentDate, numberOfLessons: lessons))
////                }
////            }
////            
////        case "Month":
////            let startOfMonth = calendar.startOfDay(for: Date())
////            var weeklyLessons: [Int] = Array(repeating: 0, count: 4)
////            for dayOffset in 0..<30 {
////                if let currentDate = calendar.date(byAdding: .day, value: -dayOffset, to: startOfMonth) {
////                    let weekOfMonth = calendar.component(.weekOfMonth, from: currentDate) - 1
////                    let lessons = appointments
////                        .filter { calendar.isDate($0.timestamp, inSameDayAs: currentDate) }
////                        .reduce(0) { $0 + $1.times.count }
////                    if weekOfMonth < 4 {
////                        weeklyLessons[weekOfMonth] += lessons
////                    }
////                }
////            }
////            for weekIndex in 0..<4 {
////                let startOfWeek = calendar.date(byAdding: .weekOfMonth, value: -weekIndex, to: startOfMonth)!
////                let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek)!
////                let dateRange = "\(dateFormatter.string(from: startOfWeek)) - \(dateFormatter.string(from: endOfWeek))"
////                data.append(LessonData(date: startOfWeek, numberOfLessons: weeklyLessons[weekIndex], dateRange: dateRange))
////            }
////            
////        case "Year":
////                    let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: Date()))!
////                    var monthlyLessons: [Int] = Array(repeating: 0, count: 12)
////                    for monthOffset in 0..<12 {
////                        if let currentMonth = calendar.date(byAdding: .month, value: -monthOffset, to: startOfYear) {
////                            let lessons = appointments
////                                .filter { calendar.isDate($0.timestamp, equalTo: currentMonth, toGranularity: .month) }
////                                .reduce(0) { $0 + $1.times.count }
////                            monthlyLessons[monthOffset] = lessons
////                        }
////                    }
////                    for monthIndex in 0..<12 {
////                        let date = calendar.date(byAdding: .month, value: -monthIndex, to: startOfYear)!
////                        data.append(LessonData(date: date, numberOfLessons: monthlyLessons[monthIndex]))
////                    }
////        default:
////            break
////        }
////        
////        lessonData = data.sorted(by: { $0.date < $1.date })
////    }
////    
////    // Generate message for alert based on selected time period
////    func generateDetailsMessage(for lesson: LessonData?) -> String {
////        guard let lesson = lesson else { return "No data available." }
////        
////        switch selectedTimePeriod {
////        case "Month":
////            return "Week: \(lesson.dateRange ?? "Unknown")\nLessons: \(lesson.numberOfLessons)"
////        default:
////            return "Date: \(dateFormatter.string(from: lesson.date))\nLessons: \(lesson.numberOfLessons)"
////        }
////    }
////}
//
////struct LessonChartView_Previews: PreviewProvider {
////    static var previews: some View {
////        LessonChartView()
////    }
////}
