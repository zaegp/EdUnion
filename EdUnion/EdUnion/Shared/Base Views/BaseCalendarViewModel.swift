//
//  BaseCalendarViewModel.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/21.
//

import SwiftUI
import FirebaseFirestore

class BaseCalendarViewModel: ObservableObject {
    @Published var participantNames: [String: String] = [:]
    @Published var sortedActivities: [Appointment] = []
    @Published var internalDateColors: [Date: Color] = [:]
    @Published var activitiesByDate: [Date: [Appointment]] = [:]
    
    var students: [Student] = []
    @Published var studentsNotes: [String: String] = [:]
    private var appointmentListener: ListenerRegistration?
    
    var onDataUpdated: (() -> Void)?
    
    func loadAndSortActivities(for activities: [Appointment]) {
            sortActivities(by: activities)
        }
    
    func fetchUserData<T: UserProtocol & Decodable>(from collection: String, userID: String, as type: T.Type, completion: (() -> Void)? = nil) {
        UserFirebaseService.shared.fetchUser(from: collection, by: userID, as: type) { [weak self] result in
            switch result {
            case .success(let user):
                DispatchQueue.main.async {
                    if let student = user as? Student {
                        self?.participantNames[userID] = student.fullName.isEmpty ? "未知学生" : student.fullName
                    } else if let teacher = user as? Teacher {
                        self?.participantNames[userID] = teacher.fullName.isEmpty ? "未知老师" : teacher.fullName
                    }
                    completion?()
                }
            case .failure:
                DispatchQueue.main.async {
                    let unknownLabel = collection == "students" ? "未知学生" : "未知老师"
                    self?.participantNames[userID] = unknownLabel
                    completion?()
                }
            }
        }
    }
    
    func sortActivities(by activities: [Appointment], ascending: Bool = false) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm" 

        sortedActivities = activities.sorted { (a, b) -> Bool in
            guard let timeAFull = a.times.first,
                  let timeBFull = b.times.first,
                  let startTimeAString = timeAFull.split(separator: "-").first?.trimmingCharacters(in: .whitespaces),
                  let startTimeBString = timeBFull.split(separator: "-").first?.trimmingCharacters(in: .whitespaces),
                  let dateA = dateFormatter.date(from: startTimeAString),
                  let dateB = dateFormatter.date(from: startTimeBString) else {
                return false
            }
            return ascending ? dateA > dateB : dateA < dateB
        }
        print("Activities sorted: \(sortedActivities.map { $0.times.first ?? "" })")
    }
    
    func saveNoteText(_ noteText: String, for studentID: String, teacherID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        UserFirebaseService.shared.updateStudentNotes(forTeacher: teacherID, studentID: studentID, note: noteText) { [weak self] result in
            switch result {
            case .success:
                self?.studentsNotes[studentID] = noteText
                self?.onDataUpdated?()
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func fetchStudents(for teacherID: String) {
        UserFirebaseService.shared.fetchTeacherStudentList(teacherID: teacherID) { [weak self] result in
            switch result {
            case .success(let studentsNotes):
                self?.studentsNotes = studentsNotes
                self?.handleFetchedData(studentsNotes)
            case .failure(let error):
                print("取得學生資料失敗: \(error.localizedDescription)")
            }
        }
    }
    
    private func handleFetchedData(_ studentsNotes: [String: String]) {
        var fetchedStudents: [Student] = []
        let dispatchGroup = DispatchGroup()
        
        for (studentID, _) in studentsNotes {
            dispatchGroup.enter()
            
            UserFirebaseService.shared.fetchUser(from: "students", by: studentID, as: Student.self) { result in
                defer { dispatchGroup.leave() }
                
                switch result {
                case .success(let student):
                    fetchedStudents.append(student)
                case .failure(let error):
                    print("取得學生 \(studentID) 資料失敗: \(error.localizedDescription)")
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.students = fetchedStudents
            self.onDataUpdated?()
        }
    }
    
    func fetchAppointments(forUserID userID: String, userRole: String) {
            appointmentListener?.remove()
            appointmentListener = AppointmentFirebaseService.shared.fetchConfirmedAppointments(
                forTeacherID: (userRole == "teacher") ? userID : nil,
                studentID: (userRole == "student") ? userID : nil
            ) { result in
                switch result {
                case .success(let fetchedAppointments):
                    DispatchQueue.main.async {
                        self.mapAppointmentsToDates(appointments: fetchedAppointments)
                    }
                case .failure(let error):
                    print("獲取預約時出錯：\(error)")
                }
            }
        }
        
        private func mapAppointmentsToDates(appointments: [Appointment]) {
            activitiesByDate.removeAll()
            var seenAppointments = Set<String>()
            var duplicateAppointments = [Appointment]()
            
            for appointment in appointments {
                if seenAppointments.contains(appointment.id!) {
                    duplicateAppointments.append(appointment)
                } else {
                    seenAppointments.insert(appointment.id!)
                }
                
                if let date = TimeService.sharedDateFormatter.date(from: appointment.date) {
                    let startOfDay = Calendar.current.startOfDay(for: date)
                    if activitiesByDate[startOfDay] != nil {
                        activitiesByDate[startOfDay]?.append(appointment)
                    } else {
                        activitiesByDate[startOfDay] = [appointment]
                    }
                }
            }
            
            if !duplicateAppointments.isEmpty {
                print("重複的預約: \(duplicateAppointments.map { $0.id })")
            }
            
            for (date, appointments) in activitiesByDate {
                let hasConfirmedAppointments = appointments.contains { $0.status.lowercased() == "confirmed" }
                if hasConfirmedAppointments {
                    internalDateColors[date] = .mainOrange
                } else {
                    internalDateColors.removeValue(forKey: date)
                }
            }
        }
    
    func cancelAppointment(appointmentID: String, completion: @escaping (Result<Void, Error>) -> Void) {
            AppointmentFirebaseService.shared.updateAppointmentStatus(appointmentID: appointmentID, status: .canceled) { result in
                completion(result)
            }
        }
        
        func generateDays(for referenceDate: Date, isWeekView: Bool) -> [CalendarDay] {
            var days: [CalendarDay] = []
            let calendar = Calendar.current
            
            if isWeekView {
                guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: referenceDate)) else {
                    return []
                }
                for i in 0..<7 {
                    if let date = calendar.date(byAdding: .day, value: i, to: startOfWeek) {
                        days.append(CalendarDay(date: date))
                    }
                }
            } else {
                guard let range = calendar.range(of: .day, in: .month, for: referenceDate) else { return [] }
                let numDays = range.count
                
                guard let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: referenceDate)) else { return [] }
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
            
            return days
        }
}
