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
//    var pendingAppointments: [Appointment] = [] {
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
//        UserFirebaseService.shared.fetchStudentNote(studentID: studentID) { [weak self] result in
//            switch result {
//            case .success(let studentNote):
//                self?.studentNote = ((studentNote?.isEmpty ?? true) ? "沒有備註" : studentNote) ?? "沒有備註"
//                self?.updateUI?()
//            case .failure(let error):
//                print("獲取學生備註時出錯: \(error.localizedDescription)")
//                self?.studentNote = "Unknown Student"
//                self?.updateUI?()
//            }
//        }
//    }
//    
//    func fetchTodayAppointments(completion: (() -> Void)? = nil) {
//        AppointmentFirebaseService.shared.fetchTodayAppointments { [weak self] result in
//            switch result {
//            case .success(let fetchedAppointments):
//                self?.appointments = fetchedAppointments
//                completion?()
//            case .failure(let error):
//                print("Error fetching appointments: \(error.localizedDescription)")
//                completion?()
//            }
//        }
//    }
//    
//    func listenToPendingAppointments() {
//            AppointmentFirebaseService.shared.listenToPendingAppointments { [weak self] result in
//                switch result {
//                case .success(let fetchedAppointments):
//                    self?.pendingAppointments = fetchedAppointments
//                case .failure(let error):
//                    print("Error listening to pending appointments: \(error.localizedDescription)")
//                }
//            }
//        }
//    
//    var completedAppointmentsCount: Int {
//        return appointments.filter { $0.status == "completed" }.count
//    }
//    
//    var progressValue: Double {
//        guard appointments.count > 0 else { return 0 }
//        return Double(completedAppointmentsCount) / Double(appointments.count)
//    }
//    
//    func completeCourse(appointmentID: String, teacherID: String) {
//        AppointmentFirebaseService.shared.updateAppointmentStatus(appointmentID: appointmentID, status: .completed) { [weak self] result in
//            switch result {
//            case .success:
//                print("預約已確認")
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
//                self?.listenToPendingAppointments()
//            case .failure(let error):
//                print("更新預約狀態失敗: \(error.localizedDescription)")
//            }
//        }
//    }
//    
//    func getPendingAppointmentsCount() -> Int {
//        return pendingAppointments.count
//    }
//}

class TodayCoursesViewModel: ObservableObject {
    
    private let db = Firestore.firestore()
    let userID = UserSession.shared.currentUserID ?? ""
    
    @Published var appointments: [Appointment] = [] {
        didSet {
            self.updateUI?()
        }
    }
    
    @Published var pendingAppointments: [Appointment] = [] {
        didSet {
            self.updateUI?()
        }
    }
    
    @Published var studentNames: [String: String] = [:] // studentID: name
    @Published var studentNotes: [String: String] = [:] // studentID: note
    
    var updateUI: (() -> Void)?
    
    // 獲取學生名稱，如果已經緩存則不再重新獲取
    func fetchStudentName(for studentID: String, completion: (() -> Void)? = nil) {
        if studentNames[studentID] != nil {
            completion?()
            return
        }
        
        UserFirebaseService.shared.fetchName(from: "students", by: studentID) { [weak self] result in
            switch result {
            case .success(let studentName):
                DispatchQueue.main.async {
                    self?.studentNames[studentID] = (studentName?.isEmpty == false) ? studentName : "Unknown Student"
                    completion?()
                }
            case .failure:
                DispatchQueue.main.async {
                    self?.studentNames[studentID] = "Unknown Student"
                    completion?()
                }
            }
        }
    }
    
    // 獲取學生備註，如果已經緩存則不再重新獲取
    func fetchStudentNote(for studentID: String, completion: (() -> Void)? = nil) {
        if studentNotes[studentID] != nil {
            completion?()
            return
        }
        
        UserFirebaseService.shared.fetchStudentNote(studentID: studentID) { [weak self] result in
            switch result {
            case .success(let note):
                DispatchQueue.main.async {
                    self?.studentNotes[studentID] = (note?.isEmpty == false) ? note : "沒有備註"
                    completion?()
                }
            case .failure:
                DispatchQueue.main.async {
                    self?.studentNotes[studentID] = "沒有備註"
                    completion?()
                }
            }
        }
    }
    
    // 獲取並排序今天的預約
    func fetchTodayAppointments(completion: (() -> Void)? = nil) {
            AppointmentFirebaseService.shared.fetchTodayAppointments { [weak self] result in
                switch result {
                case .success(let fetchedAppointments):
                    // 先排序
                    let sortedAppointments = TimeService.sortCourses(by: fetchedAppointments, ascending: false)
                    print("Fetched appointments sorted")
                    // 再獲取所有相關學生的名稱和備註
                    self?.fetchAllStudentData(for: sortedAppointments) {
                        // 在所有學生數據加載完成後設置 appointments
                        self?.appointments = sortedAppointments
                        print("Set appointments")
                        completion?()
                    }
                case .failure(let error):
                    print("Error fetching appointments: \(error.localizedDescription)")
                    completion?()
                }
            }
        }
    
    // 獲取所有相關學生的名稱和備註
    private func fetchAllStudentData(for appointments: [Appointment], completion: (() -> Void)? = nil) {
        let studentIDs = Set(appointments.compactMap { $0.studentID })
        let group = DispatchGroup()
        
        for studentID in studentIDs {
            group.enter()
            fetchStudentName(for: studentID) {
                group.leave()
            }
            group.enter()
            fetchStudentNote(for: studentID) {
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            print("All student names and notes fetched")
            completion?()
        }
    }
    
    // 監聽待處理的預約
    func listenToPendingAppointments() {
        AppointmentFirebaseService.shared.listenToPendingAppointments { [weak self] result in
            switch result {
            case .success(let fetchedAppointments):
                self?.pendingAppointments = fetchedAppointments
            case .failure(let error):
                print("Error listening to pending appointments: \(error.localizedDescription)")
            }
        }
    }
    
    // 已完成的預約數量
    var completedAppointmentsCount: Int {
        return appointments.filter { $0.status == "completed" }.count
    }
    
    // 完成進度值
    var progressValue: Double {
        guard appointments.count > 0 else { return 0 }
        return Double(completedAppointmentsCount) / Double(appointments.count)
    }
    
    // 完成課程
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
                self?.listenToPendingAppointments()
            case .failure(let error):
                print("更新預約狀態失敗: \(error.localizedDescription)")
            }
        }
    }
    
    // 獲取待處理的預約數量
    func getPendingAppointmentsCount() -> Int {
        return pendingAppointments.count
    }
}
