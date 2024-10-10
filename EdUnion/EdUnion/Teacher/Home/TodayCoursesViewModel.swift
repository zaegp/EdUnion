//
//  TodayCoursesViewModel.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/18.
//

import FirebaseFirestore

//class TodayCoursesViewModel {
//    
//    private let db = Firestore.firestore()
//    var studentNote: String = ""
//    let userID = UserSession.shared.currentUserID ?? ""
//    var appointments: [Appointment] = [] {
//        didSet {
//            self.updateUI?()
//        }
//    }
//    var pendingappointments: [Appointment] = [] {
//        didSet {
//            self.updateUI?()
//        }
//    }
//    
//    var updateUI: (() -> Void)?
//    
//    func fetchStudentName(for appointment: Appointment, completion: @escaping (String) -> Void) {
//        UserFirebaseService.shared.fetchName(from: "students", by: appointment.studentID) { result in
//            switch result {
//            case .success(let studentName):
//                completion(studentName ?? "Unknown Student")
//            case .failure:
//                completion("Unknown Student")
//            }
//        }
//    }
//    
//    func fetchStudentNote(teacherID: String, studentID: String) {
//            UserFirebaseService.shared.fetchStudentNote(teacherID: teacherID, studentID: studentID) { [weak self] result in
//                switch result {
//                case .success(let studentNote):
//                    self?.studentNote = studentNote ?? "沒有備註"
//                    self?.updateUI?()
//                case .failure(let error):
//                    print("獲取學生備註時出錯: \(error.localizedDescription)")
//                    self?.studentNote = "Unknown Student"
//                    self?.updateUI?()
//                }
//            }
//        }
//    
//    func fetchTodayAppointments() {
//        AppointmentFirebaseService.shared.fetchTodayAppointments { [weak self] result in
//            switch result {
//            case .success(let fetchedAppointments):
//                self?.appointments = fetchedAppointments
//            case .failure(let error):
//                print("Error fetching appointments: \(error.localizedDescription)")
//            }
//        }
//    }
//    
//    var completedAppointmentsCount: Int {
//           return appointments.filter { $0.status == "completed" }.count
//       }
//       
//       var progressValue: Double {
//           guard appointments.count > 0 else { return 0 }
//           return Double(completedAppointmentsCount) / Double(appointments.count)
//       }
//    
//    func completeCourse(appointmentID: String, teacherID: String) {
//        AppointmentFirebaseService.shared.updateAppointmentStatus(appointmentID: appointmentID, status: .completed) { [weak self] result in
//            switch result {
//            case .success:
//                if let index = self?.appointments.firstIndex(where: { $0.id == appointmentID }) {
//                    self?.appointments[index].status = "completed"
//                }
//                
//                AppointmentFirebaseService.shared.incrementTeacherTotalCourses() { result in
//                    switch result {
//                    case .success:
//                        print("Successfully incremented totalCourses for teacher.")
//                    case .failure(let error):
//                        print("Failed to increment totalCourses: \(error.localizedDescription)")
//                    }
//                }
//                
//            case .failure(let error):
//                print("更新預約狀態失敗: \(error.localizedDescription)")
//            }
//        }
//    }
//    
//    func loadPendingAppointments() {
//        AppointmentFirebaseService.shared.fetchPendingAppointments(forTeacherID: userID) { result in
//            switch result {
//            case .success(let fetchedAppointments):
//                self.pendingappointments = fetchedAppointments
//            case .failure(let error):
//                print("加載預約失敗：\(error.localizedDescription)")
//            }
//        }
//    }
//    
//    func getPendingAppointmentsCount() -> Int {
//            return pendingappointments.count
//        }
//}

class TodayCoursesViewModel {
    
    private let db = Firestore.firestore()
    var studentNote: String = ""
    let userID = UserSession.shared.currentUserID ?? ""
    var appointments: [Appointment] = [] {
        didSet {
            self.updateUI?()
        }
    }
    var pendingAppointments: [Appointment] = [] {
        didSet {
            self.updateUI?()
        }
    }
    
    var updateUI: (() -> Void)?
    
    func fetchStudentName(for appointment: Appointment, completion: @escaping (String) -> Void) {
        UserFirebaseService.shared.fetchName(from: "students", by: appointment.studentID) { result in
            switch result {
            case .success(let studentName):
                completion(studentName ?? "Unknown Student")
            case .failure:
                completion("Unknown Student")
            }
        }
    }
    
    func fetchStudentNote(teacherID: String, studentID: String) {
        UserFirebaseService.shared.fetchStudentNote(teacherID: teacherID, studentID: studentID) { [weak self] result in
            switch result {
            case .success(let studentNote):
                self?.studentNote = studentNote ?? "沒有備註"
                self?.updateUI?()
            case .failure(let error):
                print("獲取學生備註時出錯: \(error.localizedDescription)")
                self?.studentNote = "Unknown Student"
                self?.updateUI?()
            }
        }
    }
    
    func fetchTodayAppointments(completion: (() -> Void)? = nil) {
        AppointmentFirebaseService.shared.fetchTodayAppointments { [weak self] result in
            switch result {
            case .success(let fetchedAppointments):
                self?.appointments = fetchedAppointments
                completion?()
            case .failure(let error):
                print("Error fetching appointments: \(error.localizedDescription)")
                completion?()
            }
        }
    }
    
    func fetchPendingAppointments(completion: (() -> Void)? = nil) {
        AppointmentFirebaseService.shared.fetchPendingAppointments(forTeacherID: userID) { [weak self] result in
            switch result {
            case .success(let fetchedAppointments):
                self?.pendingAppointments = fetchedAppointments
                print("Fetched pending appointments: \(fetchedAppointments.count)")
                completion?()
            case .failure(let error):
                print("Error fetching pending appointments: \(error.localizedDescription)")
                completion?()
            }
        }
    }
    
    var completedAppointmentsCount: Int {
        return appointments.filter { $0.status == "completed" }.count
    }
    
    var progressValue: Double {
        guard appointments.count > 0 else { return 0 }
        return Double(completedAppointmentsCount) / Double(appointments.count)
    }
    
    func completeCourse(appointmentID: String, teacherID: String) {
        AppointmentFirebaseService.shared.updateAppointmentStatus(appointmentID: appointmentID, status: .completed) { [weak self] result in
            switch result {
            case .success:
                print("預約已確認")
                if let index = self?.appointments.firstIndex(where: { $0.id == appointmentID }) {
                    self?.appointments[index].status = "completed"
                }
                
                AppointmentFirebaseService.shared.incrementTeacherTotalCourses() { result in
                    switch result {
                    case .success:
                        print("Successfully incremented totalCourses for teacher.")
                    case .failure(let error):
                        print("Failed to increment totalCourses: \(error.localizedDescription)")
                    }
                }
                self?.fetchPendingAppointments()
            case .failure(let error):
                print("更新預約狀態失敗: \(error.localizedDescription)")
            }
        }
    }
    
    func loadPendingAppointments() {
        AppointmentFirebaseService.shared.fetchPendingAppointments(forTeacherID: userID) { result in
            switch result {
            case .success(let fetchedAppointments):
                self.pendingAppointments = fetchedAppointments
            case .failure(let error):
                print("加載預約失敗：\(error.localizedDescription)")
            }
        }
    }
    
    func getPendingAppointmentsCount() -> Int {
        return pendingAppointments.count
    }
}
