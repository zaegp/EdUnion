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
    
    // 已確認的預約
    func fetchConfirmedAppointments(forTeacherID teacherID: String, completion: @escaping (Result<[Appointment], Error>) -> Void) {
        db.collection("appointments")
            .whereField("teacherID", isEqualTo: teacherID)
            .whereField("status", isEqualTo: "confirmed")
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("查詢失敗：\(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("沒有找到符合條件的預約。")
                    completion(.success([]))
                    return
                }
                
                do {
                    let appointments = try documents.compactMap { try $0.data(as: Appointment.self) }
                    completion(.success(appointments))
                } catch {
                    print("解析預約時出錯：\(error)")
                    completion(.failure(error))
                }
            }
    }
    
    // 取得今日課程
    func fetchTodayConfirmedAppointments(completion: @escaping (Result<[Appointment], Error>) -> Void) {
        let todayDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayDateString = dateFormatter.string(from: todayDate)
        
        db.collection("appointments")
            .whereField("date", isEqualTo: todayDateString)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    completion(.success([]))  // 沒有數據
                    return
                }
                
                let appointments = documents.compactMap { try? $0.data(as: Appointment.self) }
                completion(.success(appointments))
            }
    }
    
    // 更新老師的總課程數
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
    
    // 老師：確認預約頁面
    func fetchPendingAppointments(forTeacherID teacherID: String, completion: @escaping (Result<[Appointment], Error>) -> Void) {
        db.collection("appointments")
            .whereField("teacherID", isEqualTo: teacherID)
            .whereField("status", isEqualTo: "pending")
            .getDocuments { querySnapshot, error in
                if let error = error {
                    print("獲取預約失敗：\(error.localizedDescription)")
                    completion(.failure(error))
                } else {
                    guard let documents = querySnapshot?.documents else {
                        completion(.success([]))
                        return
                    }
                    
                    let appointments = documents.compactMap { try? $0.data(as: Appointment.self) }
                    completion(.success(appointments))
                }
            }
    }
    
    // MARK: - 確認預約後更新
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
