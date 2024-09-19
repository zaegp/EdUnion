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
    
    func fetchTodayAppointments() {
        AppointmentFirebaseService.shared.fetchTodayAppointments { [weak self] result in
            switch result {
            case .success(let fetchedAppointments):
                self?.appointments = fetchedAppointments
            case .failure(let error):
                print("Error fetching appointments: \(error.localizedDescription)")
            }
        }
    }
    
    var completedAppointmentsCount: Int {
           return appointments.filter { $0.status == "completed" }.count
       }
       
       // 計算進度值
       var progressValue: Double {
           guard appointments.count > 0 else { return 0 }
           return Double(completedAppointmentsCount) / Double(appointments.count)
       }
    
    func completeCourse(appointmentID: String, teacherID: String) {
        AppointmentFirebaseService.shared.updateAppointmentStatus(appointmentID: appointmentID, status: .completed) { [weak self] result in
            switch result {
            case .success:
                print("預約已完成")
                
                // 本地更新課程狀態
                if let index = self?.appointments.firstIndex(where: { $0.id == appointmentID }) {
                    self?.appointments[index].status = "completed"
                }
                
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
