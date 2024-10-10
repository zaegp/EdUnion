//
//  ConfirmViewModel.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/17.
//

import Foundation

//class ConfirmViewModel {
//    
//    var appointments: [Appointment] = [] {
//        didSet {
//            self.updateUI?()
//        }
//    }
//    
//    var userID: String
//    var updateUI: (() -> Void)?
//    
//    init() {
//        self.userID = UserSession.shared.currentUserID ?? ""
//    }
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
//    func getPendingAppointmentsCount() -> Int {
//           return appointments.count
//       }
//    
//    func loadPendingAppointments() {
//        AppointmentFirebaseService.shared.fetchPendingAppointments(forTeacherID: userID ?? "") { result in
//            switch result {
//            case .success(let fetchedAppointments):
//                self.appointments = fetchedAppointments
//            case .failure(let error):
//                print("加載預約失敗：\(error.localizedDescription)")
//            }
//        }
//    }
//    
//    func confirmAppointment(appointmentID: String) {
//        AppointmentFirebaseService.shared.updateAppointmentStatus(appointmentID: appointmentID, status: .confirmed) { result in
//            switch result {
//            case .success:
//                print("預約已確認")
//                self.loadPendingAppointments()
//                // 發送通知來更新 bell badge
//                NotificationCenter.default.post(name: Notification.Name("UpdateBellBadge"), object: nil)
//            case .failure(let error):
//                print("更新預約狀態失敗: \(error.localizedDescription)")
//            }
//        }
//    }
//
//    func rejectAppointment(appointmentID: String) {
//        AppointmentFirebaseService.shared.updateAppointmentStatus(appointmentID: appointmentID, status: .rejected) { result in
//            switch result {
//            case .success:
//                print("預約已拒絕")
//                self.loadPendingAppointments() 
//            case .failure(let error):
//                print("更新預約狀態失敗: \(error.localizedDescription)")
//            }
//        }
//    }
//    
//    func updateStudentNotes(studentID: String, note: String, completion: @escaping (Result<Bool, Error>) -> Void) {
//        UserFirebaseService.shared.updateStudentNotes(forTeacher: userID, studentID: studentID, note: note) { result in
//            switch result {
//            case .success(let studentExists):
//                completion(.success(studentExists))
//            case .failure(let error):
//                completion(.failure(error))
//            }
//        }
//    }
//}

class ConfirmViewModel {
    
    var appointments: [Appointment] = [] {
        didSet {
            self.updateUI?()
        }
    }
    
    var userID: String
    var updateUI: (() -> Void)?
    
    init() {
        self.userID = UserSession.shared.currentUserID ?? ""
    }
    
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
    
    func getPendingAppointmentsCount() -> Int {
        return appointments.count
    }
    
    func loadPendingAppointments() {
        AppointmentFirebaseService.shared.fetchPendingAppointments(forTeacherID: userID) { [weak self] result in
            switch result {
            case .success(let fetchedAppointments):
                self?.appointments = fetchedAppointments
            case .failure(let error):
                print("加載預約失敗：\(error.localizedDescription)")
            }
        }
    }
    
    func confirmAppointment(appointmentID: String) {
        AppointmentFirebaseService.shared.updateAppointmentStatus(appointmentID: appointmentID, status: .confirmed) { result in
            switch result {
            case .success:
                print("預約已確認")
                self.loadPendingAppointments()
                // 發送通知來更新 bell badge
                NotificationCenter.default.post(name: Notification.Name("UpdateBellBadge"), object: nil)
            case .failure(let error):
                print("更新預約狀態失敗: \(error.localizedDescription)")
            }
        }
    }

    func rejectAppointment(appointmentID: String) {
        AppointmentFirebaseService.shared.updateAppointmentStatus(appointmentID: appointmentID, status: .rejected) { result in
            switch result {
            case .success:
                print("預約已拒絕")
                self.loadPendingAppointments()
                // 發送通知來更新 bell badge
                NotificationCenter.default.post(name: Notification.Name("UpdateBellBadge"), object: nil)
            case .failure(let error):
                print("更新預約狀態失敗: \(error.localizedDescription)")
            }
        }
    }
    
    func updateStudentNotes(studentID: String, note: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        UserFirebaseService.shared.updateStudentNotes(forTeacher: userID, studentID: studentID, note: note) { result in
            switch result {
            case .success(let studentExists):
                completion(.success(studentExists))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
