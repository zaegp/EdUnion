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
    
    // MARK: - TimeSlots Operations
    
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
    
    func saveDateColorToFirebase(date: Date, color: Color) {
            let colorHex = color.toHex()  // 将颜色转换为 Hex 字符串
            let dateString = dateFormatter.string(from: date)  // 将日期转换为字符串

            let teacherRef = FirebaseService.shared.db.collection("teachers").document("001")
            
            // 更新 selectedTimeSlots Map 中的值
            teacherRef.updateData([
                "selectedTimeSlots.\(dateString)": colorHex  // 以日期为键，颜色为值
            ]) { error in
                if let error = error {
                    print("保存日期颜色时出错：\(error)")
                } else {
                    print("日期颜色成功保存！")
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
    
    func updateTimeSlot(oldTimeSlot: AvailableTimeSlot, newTimeSlot: AvailableTimeSlot, forTeacher teacherID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let oldTimeSlotData = oldTimeSlot.toDictionary()
        let newTimeSlotData = newTimeSlot.toDictionary()
        let teacherRef = db.collection("teachers").document(teacherID)
        
        teacherRef.updateData([
            "timeSlots": FieldValue.arrayRemove([oldTimeSlotData])
        ]) { error in
            if let error = error {
                print("移除旧时间段时出错：\(error)")
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
}
