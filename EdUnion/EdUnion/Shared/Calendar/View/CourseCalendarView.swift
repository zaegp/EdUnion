////
////  CourseCalendarView.swift
////  EdUnion
////
////  Created by Rowan Su on 2024/9/19.
////
//
//import SwiftUI
//
//struct CourseCalendarView: View {
//    @State private var selectedDay: Date? = nil
//    @State private var appointments: [Appointment] = []
//    @State private var activitiesByDate: [Date: [Appointment]] = [:]
//    
//    var body: some View {
//        BaseCalendarView(selectedDay: $selectedDay)
//            .onAppear {
//                fetchAppointments()
//            }
//            .overlay(
//                Group {
//                    if let selectedDay = selectedDay, let activities = activitiesByDate[selectedDay] {
//                        List {
//                            ForEach(activities) { appointment in
//                                ForEach(appointment.times, id: \.self) { time in
//                                    HStack {
//                                        Text("學生 ID: \(appointment.studentID)")
//                                        Text(time)
//                                    }
//                                }
//                            }
//                        }
//                        .frame(maxHeight: 200)
//                    } else {
//                        EmptyView()  // 當條件不成立時，返回一個空視圖
//                    }
//                }
//            )
//    }
//    
//    private func fetchAppointments() {
//        AppointmentFirebaseService.shared.fetchConfirmedAppointments(forTeacherID: teacherID) { result in
//            switch result {
//            case .success(let fetchedAppointments):
//                DispatchQueue.main.async {
//                    self.appointments = fetchedAppointments
//                    self.mapAppointmentsToDates()
//                }
//            case .failure(let error):
//                print("獲取預約時出錯：\(error)")
//            }
//        }
//    }
//    
//    private func mapAppointmentsToDates() {
//           activitiesByDate.removeAll()
//   
//           for appointment in appointments {
//               if let date = dateFormatter.date(from: appointment.date) {
//                   let startOfDay = Calendar.current.startOfDay(for: date)
//                   if activitiesByDate[startOfDay] != nil {
//                       activitiesByDate[startOfDay]?.append(appointment)
//                   } else {
//                       activitiesByDate[startOfDay] = [appointment]
//                   }
//               }
//           }
//       }
//    
//    private let dateFormatter: DateFormatter = {
//           let formatter = DateFormatter()
//           formatter.dateFormat = "yyyy-MM-dd"
//           formatter.timeZone = TimeZone.current
//           return formatter
//       }()
//}
//
//
//
////#Preview {
////    CourseCalendarView()
////}
