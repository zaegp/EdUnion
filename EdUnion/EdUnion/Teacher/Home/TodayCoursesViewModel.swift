//
//  TodayCoursesViewModel.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/18.
//

import FirebaseFirestore

class TodayCoursesViewModel {
    
    private let db = Firestore.firestore()
    var appointments: [Appointment] = [] {
        didSet {
            self.updateUI?()
        }
    }
    
    var updateUI: (() -> Void)?
    
    func fetchTodayConfirmedAppointments() {
        AppointmentFirebaseService.shared.fetchTodayConfirmedAppointments { [weak self] result in
            switch result {
            case .success(let fetchedAppointments):
                self?.appointments = fetchedAppointments
            case .failure(let error):
                print("Error fetching appointments: \(error.localizedDescription)")
            }
        }
    }
    
    func completeCourse(appointmentID: String, teacherID: String) {
        AppointmentFirebaseService.shared.updateAppointmentStatus(appointmentID: appointmentID, status: .completed) { [weak self] result in
            switch result {
            case .success:
                print("預約已完成")
                
                // 更新老師的總課程數
                AppointmentFirebaseService.shared.incrementTeacherTotalCourses(teacherID: teacherID) { result in
                    switch result {
                    case .success:
                        print("Successfully incremented totalCourses for teacher.")
                    case .failure(let error):
                        print("Failed to increment totalCourses: \(error.localizedDescription)")
                    }
                }
                
            case .failure(let error):
                print("更新預約狀態失敗: \(error.localizedDescription)")
            }
        }
    }
}
