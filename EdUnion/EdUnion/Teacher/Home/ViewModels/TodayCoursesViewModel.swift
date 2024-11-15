//
//  TodayCoursesViewModel.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/18.
//

import FirebaseFirestore

class TodayCoursesViewModel: ObservableObject {
    
    private let db = Firestore.firestore()
    let userID = UserSession.shared.currentUserID ?? ""
    @Published var pendingAppointmentsCount: Int = 0
    @Published var appointments: [Appointment] = [] {
        didSet {
            self.updateUI?()
            checkCoursesEmpty()
        }
    }
    
    @Published var pendingAppointments: [Appointment] = [] {
        didSet {
            self.updateUI?()
        }
    }
    
    @Published var studentNames: [String: String] = [:]
    @Published var studentNotes: [String: String] = [:]
    @Published var isCoursesEmpty: Bool = true
    
    var updateUI: (() -> Void)?
    
    func fetchStudentName(for studentID: String, completion: (() -> Void)? = nil) {
        if studentNames[studentID] != nil {
            completion?()
            return
        }
        
        UserFirebaseService.shared.fetchName(from: Constants.studentsCollection, by: studentID) { [weak self] result in
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
    
    func saveNoteText(
        _ noteText: String,
        for studentID: String,
        teacherID: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        UserFirebaseService.shared.updateStudentNotes(studentID: studentID, note: noteText) { [weak self] result in
                switch result {
                case .success:
                    self?.studentNotes[studentID] = noteText
                    print("成功保存備註")
                    completion(.success(()))
                case .failure(let error):
                    print("保存備註時發生錯誤: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
    }
    
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
    
    func fetchTodayAppointments(completion: (() -> Void)? = nil) {
            AppointmentFirebaseService.shared.fetchTodayAppointments { [weak self] result in
                switch result {
                case .success(let fetchedAppointments):
                    let sortedAppointments = TimeService.sortCourses(by: fetchedAppointments, ascending: false)
                    print("Fetched appointments sorted")
                    self?.fetchAllStudentData(for: sortedAppointments) {
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
    
    func listenToPendingAppointments() {
        AppointmentFirebaseService.shared.listenToPendingAppointments { [weak self] result in
            switch result {
            case .success(let fetchedAppointments):
                self?.pendingAppointments = fetchedAppointments
                self?.pendingAppointmentsCount = fetchedAppointments.count
            case .failure(let error):
                print("Error listening to pending appointments: \(error.localizedDescription)")
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
                
                AppointmentFirebaseService.shared.incrementTeacherTotalCourses { result in
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
    
    func getPendingAppointmentsCount() -> Int {
        return pendingAppointments.count
    }
    
    private func checkCoursesEmpty() {
        isCoursesEmpty = appointments.isEmpty
    }
}
