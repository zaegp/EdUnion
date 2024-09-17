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
    
    var teacherID: String 
    var updateUI: (() -> Void)?
    
    init(teacherID: String) {
        self.teacherID = teacherID
    }
    
    func loadPendingAppointments() {
        FirebaseService.shared.fetchPendingAppointments(forTeacherID: teacherID) { result in
            switch result {
            case .success(let fetchedAppointments):
                self.appointments = fetchedAppointments
            case .failure(let error):
                print("加載預約失敗：\(error.localizedDescription)")
            }
        }
    }
    
    func confirmAppointment(appointmentID: String) {
        FirebaseService.shared.updateAppointmentStatus(appointmentID: appointmentID, status: "confirmed") { result in
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
        FirebaseService.shared.updateAppointmentStatus(appointmentID: appointmentID, status: "rejected") { result in
            switch result {
            case .success:
                print("預約已拒絕")
                self.loadPendingAppointments()  // 使用屬性 teacherID 重新加載
            case .failure(let error):
                print("更新預約狀態失敗: \(error.localizedDescription)")
            }
        }
    }
}
