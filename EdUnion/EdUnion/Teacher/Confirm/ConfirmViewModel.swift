//
//  ConfirmViewModel.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/17.
//

import Foundation

class ConfirmViewModel {
    
    var appointments: [Appointment] {
        didSet {
            self.updateUI?()
        }
    }
    
    var userID: String
    var updateUI: (() -> Void)?
    
    init(appointments: [Appointment], userID: String) {
        self.appointments = appointments
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
    
    func getPendingAppointmentsCount() -> Int {
        return appointments.count
    }
    
    func confirmAppointment(appointmentID: String) {
        AppointmentFirebaseService.shared.updateAppointmentStatus(appointmentID: appointmentID, status: .confirmed) { [weak self] result in
            switch result {
            case .success:
                print("預約已確認")
                self?.appointments.removeAll { $0.id == appointmentID }
                self?.updateUI?()
            case .failure(let error):
                print("更新預約狀態失敗: \(error.localizedDescription)")
            }
        }
    }

    func rejectAppointment(appointmentID: String) {
        AppointmentFirebaseService.shared.updateAppointmentStatus(appointmentID: appointmentID, status: .rejected) { [weak self] result in
            switch result {
            case .success:
                print("預約已拒絕")
                self?.appointments.removeAll { $0.id == appointmentID }
                self?.updateUI?()
            case .failure(let error):
                print("更新預約狀態失敗: \(error.localizedDescription)")
            }
        }
    }
    
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
    func updateStudentNotes(studentID: String, note: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        let notesRef = UserFirebaseService.shared.db.collection("studentsNotes").document("notes")
        
        notesRef.getDocument { (document, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let document = document, document.exists {
                let data = document.data()
                if let _ = data?[studentID] {
                    // 學生 ID 已經存在，不進行更新
                    completion(.success(true)) // 假設已存在，傳回 true
                    return
                } else {
                    // 學生 ID 不存在，進行更新
                    notesRef.updateData([studentID: note]) { error in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            completion(.success(false)) // 更新成功，傳回 false 表示之前不存在
                        }
                    }
                }
            } else {
                // 文檔不存在，創建文檔並添加學生 ID 和 note
                notesRef.setData([studentID: note]) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(false)) // 更新成功，傳回 false 表示之前不存在
                    }
                }
            }
        }
    }
}
