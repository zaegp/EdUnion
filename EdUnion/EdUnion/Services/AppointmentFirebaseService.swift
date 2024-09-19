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
                completion(.success(appointments))  // 不過濾 status，返回所有預約
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
    func fetchConfirmedAppointments(forTeacherID teacherID: String, completion: @escaping (Result<[Appointment], Error>) -> Void) {
        fetchDocuments(db.collection("appointments"), where: "teacherID", isEqualTo: teacherID) { (result: Result<[Appointment], Error>) in
            switch result {
            case .success(let appointments):
                // 過濾確認狀態
                let confirmedAppointments = appointments.filter { $0.status == "confirmed" }
                completion(.success(confirmedAppointments))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - 今日已確認的預約
    func fetchTodayAppointments(completion: @escaping (Result<[Appointment], Error>) -> Void) {
        let todayDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayDateString = dateFormatter.string(from: todayDate)
        
        fetchDocuments(db.collection("appointments"), where: "date", isEqualTo: todayDateString, completion: completion)
    }
    
    // MARK: - 更新老師的總課程數
    func incrementTeacherTotalCourses(teacherID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let teacherRef = db.collection("teachers").document(teacherID)
        
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
                // 過濾等待確認狀態
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
        appointmentRef.updateData(["status": status.rawValue]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
