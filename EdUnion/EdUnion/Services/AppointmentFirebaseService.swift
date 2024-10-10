//
//  AppointmentFirebaseService.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/18.
//

import FirebaseFirestore


class AppointmentFirebaseService {
    static let shared = AppointmentFirebaseService()
    private init() {}
    let userID = UserSession.shared.currentUserID ?? ""
    let db = Firestore.firestore()

    // MARK: - 通用查詢方法
    private func fetchDocuments<T: Decodable>(_ collection: CollectionReference, where field: String, isEqualTo value: Any, completion: @escaping (Result<[T], Error>) -> Void) {
        collection.whereField(field, isEqualTo: value).getDocuments { querySnapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                completion(.success([]))
                return
            }
            
            do {
                let models = try documents.compactMap { try $0.data(as: T.self) }
                completion(.success(models))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func fetchAllAppointments(forTeacherID teacherID: String, completion: @escaping (Result<[Appointment], Error>) -> Void) {
        fetchDocuments(db.collection("appointments"), where: "teacherID", isEqualTo: teacherID) { (result: Result<[Appointment], Error>) in
            switch result {
            case .success(let appointments):
                let filteredAppointments = appointments.filter { appointment in
                    appointment.status != "canceled" && appointment.status != "rejected"
                }
                completion(.success(filteredAppointments))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    // MARK: - 保存預約
    func saveBooking(data: [String: Any], completion: @escaping (Bool, Error?) -> Void) {
        db.collection("appointments").addDocument(data: data) { error in
            if let error = error {
                print("Error adding document: \(error)")
                completion(false, error)
            } else {
                print("Document successfully added!")
                completion(true, nil)
            }
        }
    }

    // MARK: - 已確認的預約
    func fetchConfirmedAppointments(forTeacherID teacherID: String? = nil, studentID: String? = nil, completion: @escaping (Result<[Appointment], Error>) -> Void) -> ListenerRegistration? {
        var query: Query = db.collection("appointments").whereField("status", isEqualTo: "confirmed")

        // 如果有提供 teacherID，則加上 teacherID 的篩選條件
        if let teacherID = teacherID {
            query = query.whereField("teacherID", isEqualTo: teacherID)
        }

        // 如果有提供 studentID，則加上 studentID 的篩選條件
        if let studentID = studentID {
            query = query.whereField("studentID", isEqualTo: studentID)
        }

        // 如果沒有提供任何一個 ID，則回傳錯誤
        guard teacherID != nil || studentID != nil else {
            completion(.failure(NSError(domain: "Missing teacherID or studentID", code: 400, userInfo: nil)))
            return nil
        }

        // 添加監聽器並處理結果
        return query.addSnapshotListener { snapshot, error in
            if let error = error {
                completion(.failure(error))
            } else if let snapshot = snapshot {
                let appointments = snapshot.documents.compactMap { doc -> Appointment? in
                    try? doc.data(as: Appointment.self)
                }
                completion(.success(appointments))
            }
        }
    }

    // MARK: - 今日確認、完成的預約
    func fetchTodayAppointments(completion: @escaping (Result<[Appointment], Error>) -> Void) {
        let todayDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayDateString = dateFormatter.string(from: todayDate)

        let confirmedQuery = db.collection("appointments")
            .whereField("date", isEqualTo: todayDateString)
            .whereField("teacherID", isEqualTo: userID)
            .whereField("status", isEqualTo: "confirmed")
        
        let completedQuery = db.collection("appointments")
            .whereField("date", isEqualTo: todayDateString)
            .whereField("teacherID", isEqualTo: userID)
            .whereField("status", isEqualTo: "completed")
        
        // 並行執行兩次查詢
        let group = DispatchGroup()
        
        var confirmedAppointments: [Appointment] = []
        var completedAppointments: [Appointment] = []
        
        var errorOccurred: Error? = nil
        
        // 查詢 confirmed 狀態
        group.enter()
        confirmedQuery.getDocuments { (snapshot, error) in
            if let error = error {
                errorOccurred = error
            } else if let documents = snapshot?.documents {
                confirmedAppointments = documents.compactMap { document -> Appointment? in
                    try? document.data(as: Appointment.self)
                }
            }
            group.leave()
        }
        
        // 查詢 completed 狀態
        group.enter()
        completedQuery.getDocuments { (snapshot, error) in
            if let error = error {
                errorOccurred = error
            } else if let documents = snapshot?.documents {
                completedAppointments = documents.compactMap { document -> Appointment? in
                    try? document.data(as: Appointment.self)
                }
            }
            group.leave()
        }
        
        // 等待所有查詢完成後，合併結果
        group.notify(queue: .main) {
            if let error = errorOccurred {
                completion(.failure(error))
            } else {
                let allAppointments = confirmedAppointments + completedAppointments
                completion(.success(allAppointments))
            }
        }
    }
    
    // MARK: - 更新老師的總課程數
    func incrementTeacherTotalCourses(completion: @escaping (Result<Void, Error>) -> Void) {
        let teacherRef = db.collection("teachers").document(userID)
        
        teacherRef.updateData([
            "totalCourses": FieldValue.increment(Int64(1))
        ]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    // MARK: - 老師：獲取待確認的預約
    func fetchPendingAppointments(forTeacherID teacherID: String, completion: @escaping (Result<[Appointment], Error>) -> Void) {
        fetchDocuments(db.collection("appointments"), where: "teacherID", isEqualTo: teacherID) { (result: Result<[Appointment], Error>) in
            switch result {
            case .success(let appointments):
                let pendingAppointments = appointments.filter { $0.status == "pending" }
                completion(.success(pendingAppointments))
            case .failure(let error):
                print("Error fetching pending appointments: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }

    // MARK: - 更新預約狀態
    func updateAppointmentStatus(appointmentID: String, status: AppointmentStatus, completion: @escaping (Result<Void, Error>) -> Void) {
        let appointmentRef = db.collection("appointments").document(appointmentID)
        print("更新狀態為: \(status.rawValue)")
        appointmentRef.updateData(["status": status.rawValue]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
