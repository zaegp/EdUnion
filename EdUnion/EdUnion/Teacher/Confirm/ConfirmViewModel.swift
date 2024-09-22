//
//  ConfirmViewModel.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/17.
//

import Foundation

class ConfirmViewModel {
    
    var appointments: [Appointment] = [] {
        didSet {
            self.updateUI?()
        }
    }
    
    var userID: String
    var updateUI: (() -> Void)?
    
    init(userID: String) {
        self.userID = userID
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
    
    func loadPendingAppointments() {
        AppointmentFirebaseService.shared.fetchPendingAppointments(forTeacherID: teacherID) { result in
            switch result {
            case .success(let fetchedAppointments):
                self.appointments = fetchedAppointments
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
            case .failure(let error):
                print("更新預約狀態失敗: \(error.localizedDescription)")
            }
        }
    }
    
    func updateStudentNotes(forTeacher teacherID: String, studentID: String, note: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        UserFirebaseService.shared.updateStudentNotes(forTeacher: teacherID, studentID: studentID, note: note) { result in
                switch result {
                case .success(let studentExists):
                    // 成功處理，返回 student 是否存在
                    completion(.success(studentExists))
                case .failure(let error):
                    // 如果有錯誤，返回錯誤結果
                    completion(.failure(error))
                }
            }
        }
}
