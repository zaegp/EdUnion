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

    private let userID = UserSession.shared.currentUserID ?? ""
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    // MARK: - 通用查詢方法
    private func fetchDocuments<T: Decodable>(
        from collection: CollectionReference,
        where field: String,
        isEqualTo value: Any,
        completion: @escaping (Result<[T], Error>) -> Void
    ) {
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

    // MARK: - 獲取教師的所有預約
    func fetchAllAppointments(
        forTeacherID teacherID: String,
        completion: @escaping (Result<[Appointment], Error>) -> Void
    ) {
        fetchDocuments(from: db.collection("appointments"), where: "teacherID", isEqualTo: teacherID) { (result: Result<[Appointment], Error>) in
            switch result {
            case .success(let appointments):
                let filteredAppointments = appointments.filter {
                    $0.status != "canceled" && $0.status != "rejected"
                }
                completion(.success(filteredAppointments))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - 儲存新預約
    func saveBooking(
        data: [String: Any],
        completion: @escaping (Bool, Error?) -> Void
    ) {
        db.collection("appointments").addDocument(data: data) { error in
            if let error = error {
                print("新增文件時出錯：\(error)")
                completion(false, error)
            } else {
                print("文件新增成功！")
                completion(true, nil)
            }
        }
    }

    // MARK: - 獲取已確認的預約
    func fetchConfirmedAppointments(
        forTeacherID teacherID: String? = nil,
        studentID: String? = nil,
        completion: @escaping (Result<[Appointment], Error>) -> Void
    ) -> ListenerRegistration? {
        var query: Query = db.collection("appointments").whereField("status", isEqualTo: "confirmed")

        if let teacherID = teacherID { query = query.whereField("teacherID", isEqualTo: teacherID) }
        if let studentID = studentID { query = query.whereField("studentID", isEqualTo: studentID) }

        guard teacherID != nil || studentID != nil else {
            completion(.failure(NSError(domain: "缺少 teacherID 或 studentID", code: 400, userInfo: nil)))
            return nil
        }

        return query.addSnapshotListener { snapshot, error in
            if let error = error {
                completion(.failure(error))
            } else if let snapshot = snapshot {
                let appointments = snapshot.documents.compactMap { try? $0.data(as: Appointment.self) }
                completion(.success(appointments))
            }
        }
    }

    // MARK: - 獲取今日預約
    func fetchTodayAppointments(completion: @escaping (Result<[Appointment], Error>) -> Void) {
        let todayDate = Date()
        let todayDateString = TimeService.sharedDateFormatter.string(from: todayDate)

        let queries = [
            db.collection(Constants.appointmentsCollection)
                .whereField("date", isEqualTo: todayDateString)
                .whereField("teacherID", isEqualTo: userID)
                .whereField("status", isEqualTo: "confirmed"),
            db.collection(Constants.appointmentsCollection)
                .whereField("date", isEqualTo: todayDateString)
                .whereField("teacherID", isEqualTo: userID)
                .whereField("status", isEqualTo: "completed")
        ]

        fetchMultipleCollections(queries: queries) { (result: Result<[Appointment], Error>) in
            switch result {
            case .success(let appointments):
                let sortedAppointments = TimeService.sortCourses(by: appointments, ascending: true)
                completion(.success(sortedAppointments))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func fetchMultipleCollections<T: Decodable>(
        queries: [Query],
        completion: @escaping (Result<[T], Error>) -> Void
    ) {
        let group = DispatchGroup()
        var results: [T] = []
        var lastError: Error?

        for query in queries {
            group.enter()
            query.getDocuments { snapshot, error in
                if let error = error {
                    lastError = error
                } else if let documents = snapshot?.documents {
                    results.append(contentsOf: documents.compactMap { try? $0.data(as: T.self) })
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            if let error = lastError {
                completion(.failure(error))
            } else {
                completion(.success(results))
            }
        }
    }

    // MARK: - 更新預約狀態
    func updateAppointmentStatus(
        appointmentID: String,
        status: AppointmentStatus,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        db.collection(Constants.appointmentsCollection).document(appointmentID).updateData(["status": status.rawValue]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    // MARK: - 更新教師總課程數
    func incrementTeacherTotalCourses(completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection(Constants.teachersCollection).document(userID).updateData([
            "totalCourses": FieldValue.increment(Int64(1))
        ]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    // MARK: - 監聽待確認的預約
    func listenToPendingAppointments(onUpdate: @escaping (Result<[Appointment], Error>) -> Void) {
        listener = db.collection(Constants.appointmentsCollection)
            .whereField("teacherID", isEqualTo: userID)
            .whereField("status", isEqualTo: "pending")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    onUpdate(.failure(error))
                } else {
                    let appointments = snapshot?.documents.compactMap { try? $0.data(as: Appointment.self) } ?? []
                    onUpdate(.success(appointments))
                }
            }
    }
}
