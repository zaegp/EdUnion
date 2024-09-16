//
//  FirebaseService.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/14.
//

import FirebaseFirestore
import SwiftUI

class FirebaseService {
    static let shared = FirebaseService()
    private init() {}
    
    let db = Firestore.firestore()
    
    // MARK: - 學生：顯示老師資訊
    func fetchTeachers(completion: @escaping (Result<[Teacher], Error>) -> Void) {
        db.collection("teachers").getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
            } else {
                let teachers = snapshot?.documents.compactMap { doc -> Teacher? in
                    return try? doc.data(as: Teacher.self)
                } ?? []
                completion(.success(teachers))
            }
        }
    }
    
    // MARK: - 老師：存可選時段
    func saveTimeSlot(_ timeSlot: AvailableTimeSlot, forTeacher teacherID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let timeSlotData = timeSlot.toDictionary()
        let teacherRef = db.collection("teachers").document(teacherID)
        
        teacherRef.setData([
            "timeSlots": FieldValue.arrayUnion([timeSlotData])
        ], merge: true) { error in
            if let error = error {
                print("Error adding time slot: \(error)")
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // MARK: - 老師：刪可選時段
    func deleteTimeSlot(_ timeSlot: AvailableTimeSlot, forTeacher teacherID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let timeSlotData = timeSlot.toDictionary()
        let teacherRef = db.collection("teachers").document(teacherID)
        
        // Use Firestore arrayRemove to delete a timeSlot from the array
        teacherRef.updateData([
            "timeSlots": FieldValue.arrayRemove([timeSlotData])
        ]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // MARK: - 老師：取可選時段
    func fetchTimeSlots(forTeacher teacherID: String, completion: @escaping (Result<[AvailableTimeSlot], Error>) -> Void) {
        let teacherRef = db.collection("teachers").document(teacherID)
        teacherRef.getDocument { (documentSnapshot, error) in
            if let error = error {
                completion(.failure(error))
            } else if let document = documentSnapshot, document.exists {
                if let data = document.data(),
                   let timeSlotsData = data["timeSlots"] as? [[String: Any]] {
                    var timeSlots: [AvailableTimeSlot] = []
                    for tsData in timeSlotsData {
                        if let timeSlot = AvailableTimeSlot.fromDictionary(tsData) {
                            timeSlots.append(timeSlot)
                        }
                    }
                    completion(.success(timeSlots))
                } else {
                    // No timeSlots found
                    completion(.success([]))
                }
            } else {
                // Document does not exist
                completion(.success([]))
            }
        }
    }
    
    // MARK: - 老師：存日期顏色對應
    func saveDateColorToFirebase(date: Date, color: Color) {
        let colorHex = color.toHex()
        let dateString = dateFormatter.string(from: date)
        
        let teacherRef = FirebaseService.shared.db.collection("teachers").document("001")
        
        teacherRef.updateData([
            "selectedTimeSlots.\(dateString)": colorHex as Any
        ]) { error in
            if let error = error {
                print("保存日期顏色時出錯：\(error)")
            } else {
                print("日期顏色成功保存！")
            }
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale.current
        return formatter
    }()
    
    // MARK: -
    func updateTimeSlot(oldTimeSlot: AvailableTimeSlot, newTimeSlot: AvailableTimeSlot, forTeacher teacherID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let oldTimeSlotData = oldTimeSlot.toDictionary()
        let newTimeSlotData = newTimeSlot.toDictionary()
        let teacherRef = db.collection("teachers").document(teacherID)
        
        teacherRef.updateData([
            "timeSlots": FieldValue.arrayRemove([oldTimeSlotData])
        ]) { error in
            if let error = error {
                print("移除舊時間段時出錯：\(error)")
                completion(.failure(error))
            } else {
                teacherRef.updateData([
                    "timeSlots": FieldValue.arrayUnion([newTimeSlotData])
                ]) { error in
                    if let error = error {
                        print("添加新时间段时出错：\(error)")
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
            }
        }
    }
    
    // MARK: - 學生：存預約資訊
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
    
    // MARK: - 學生：預約頁面扣除已被時段
    func fetchAppointments(forTeacherID teacherID: String, completion: @escaping (Result<[Appointment], Error>) -> Void) {
        db.collection("appointments")
            .whereField("teacherID", isEqualTo: teacherID)
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
    
    // MARK: - 老師：確認預約後更新
    func updateAppointmentStatus(appointmentID: String, status: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let appointmentRef = db.collection("appointments").document(appointmentID)
        appointmentRef.updateData(["status": status]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
