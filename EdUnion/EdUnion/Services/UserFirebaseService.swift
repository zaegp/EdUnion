//
//  UserFirebaseService.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/14.
//

import SwiftUI
import FirebaseFirestore
import FirebaseStorage

class UserFirebaseService {
    static let shared = UserFirebaseService()
    private init() {}
    
    let db = Firestore.firestore()
    let storage = Storage.storage()
    
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
                    completion(.success([]))
                }
            } else {
                completion(.success([]))
            }
        }
    }
    
    // MARK: - 老師：存日期顏色對應
    func saveDateColorToFirebase(date: Date, color: Color, teacherID: String) {
        let colorHex = color.toHex() // 假設你有擴展 Color 來轉換為 hex
        let dateString = dateFormatter.string(from: date) // 假設你已經有定義 dateFormatter
        
        let teacherRef = db.collection("teachers").document(teacherID)
        
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
    
    // MARK - 聊天室
    func fetchChatRooms(for participantID: String, completion: @escaping ([ChatRoom]?, Error?) -> Void) {
        db.collection("chats")
            .whereField("participants", arrayContains: participantID)
            .order(by: "lastMessageTimestamp", descending: true)
            .getDocuments { (snapshot, error) in
                if let error = error {
                    completion(nil, error)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(nil, nil)
                    return
                }
                
                let chatRooms: [ChatRoom] = documents.compactMap { document in
                    let data = document.data()
                    return ChatRoom(id: document.documentID, data: data)
                }
                completion(chatRooms, nil)
            }
    }
    
    func sendMessage(chatRoomID: String, messageData: [String: Any], completion: @escaping (Error?) -> Void) {
        let messageId = UUID().uuidString
        db.collection("chats").document(chatRoomID).collection("messages").document(messageId).setData(messageData) { error in
            completion(error)
        }
    }
    
    func updateMessage(chatRoomID: String, messageId: String, updatedData: [String: Any], completion: @escaping (Error?) -> Void) {
        db.collection("chats").document(chatRoomID).collection("messages").document(messageId).updateData(updatedData) { error in
            completion(error)
        }
    }
    
    func uploadPhoto(image: UIImage, messageId: String, completion: @escaping (String?, Error?) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            let conversionError = NSError(domain: "ImageConversionError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to JPEG format."])
            completion(nil, conversionError)
            print("Error: Failed to convert image to JPEG format.")
            return
        }
        
        let storageRef = storage.reference().child("chat_images/\(messageId).jpg")
        
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                completion(nil, error)
                print("Error uploading image: \(error.localizedDescription)")
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(nil, error)
                    print("Error fetching download URL: \(error.localizedDescription)")
                    return
                }
                
                if let urlString = url?.absoluteString {
                    print("Image uploaded successfully. URL: \(urlString)")
                    completion(urlString, nil)
                } else {
                    let urlError = NSError(domain: "DownloadURLError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to generate download URL."])
                    completion(nil, urlError)
                    print("Error: Failed to generate download URL.")
                }
            }
        }
    }
    
    func uploadAudio(audioData: Data, audioId: String, completion: @escaping (String?, Error?) -> Void) {
        let storageRef = storage.reference().child("chat_audio/\(audioId).m4a")
        
        storageRef.putData(audioData, metadata: nil) { _, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            storageRef.downloadURL { url, error in
                completion(url?.absoluteString, error)
            }
        }
    }
    
    func fetchMessages(chatRoomID: String, currentUserID: String, completion: @escaping ([Message], Error?) -> Void) {
        db.collection("chats").document(chatRoomID).collection("messages")
            .order(by: "timestamp", descending: false)
            .getDocuments { (snapshot, error) in
                if let error = error {
                    completion([], error)
                    return
                }
                
                guard let snapshot = snapshot else {
                    completion([], nil)
                    return
                }
                
                var messages: [Message] = []
                snapshot.documents.forEach { document in
                    let data = document.data()
                    let newMessage = Message(
                        ID: data["ID"] as? String ?? document.documentID,
                        type: data["type"] as? Int ?? 0,
                        content: data["content"] as? String ?? "",
                        senderID: data["senderID"] as? String ?? "",
                        isSentByCurrentUser: data["senderID"] as? String == currentUserID,
                        isSeen: data["isSeen"] as? Bool ?? false,
                        timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                    )
                    messages.append(newMessage)
                }
                completion(messages, nil)
                
                self.addMessageListener(chatRoomID: chatRoomID, currentUserID: currentUserID, completion: completion)
            }
    }
    
    func addMessageListener(chatRoomID: String, currentUserID: String, completion: @escaping ([Message], Error?) -> Void) {
        db.collection("chats").document(chatRoomID).collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    completion([], error)
                    return
                }
                
                guard let snapshot = snapshot else {
                    completion([], nil)
                    return
                }
                
                var messages: [Message] = []
                snapshot.documentChanges.forEach { diff in
                    if diff.type == .added || diff.type == .modified {
                        let data = diff.document.data()
                        let newMessage = Message(
                            ID: data["ID"] as? String ?? diff.document.documentID,
                            type: data["type"] as? Int ?? 0,
                            content: data["content"] as? String ?? "",
                            senderID: data["senderID"] as? String ?? "",
                            isSentByCurrentUser: data["senderID"] as? String == currentUserID,
                            isSeen: data["isSeen"] as? Bool ?? false,
                            timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                        )
                        messages.append(newMessage)
                    }
                }
                completion(messages, nil)
            }
    }
    
    // 老師：取今日課程
    func fetchTodayConfirmedAppointments(completion: @escaping ([Appointment]?, Error?) -> Void) {
        let db = Firestore.firestore()
        
        let todayDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayDateString = dateFormatter.string(from: todayDate)
        
        db.collection("appointments")
            .whereField("date", isEqualTo: todayDateString)
            .whereField("status", isEqualTo: "confirmed")
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error fetching appointments: \(error.localizedDescription)")
                    completion(nil, error)
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("No confirmed appointments found for today.")
                    completion([], nil)
                    return
                }
                
                var appointments: [Appointment] = []
                for document in documents {
                    if let appointment = try? document.data(as: Appointment.self) {
                        appointments.append(appointment)
                    }
                }
                
                completion(appointments, nil)
            }
    }
    
    // 使用者 ID 搜名字
    func fetchStudentName(by id: String, completion: @escaping (String?, Error?) -> Void) {
        let db = Firestore.firestore()
        
        // 查詢 students 集合中指定 id 的文檔
        db.collection("students").document(id).getDocument { (document, error) in
            if let error = error {
                // 如果出現錯誤，返回錯誤信息
                completion(nil, error)
            } else if let document = document, document.exists {
                // 成功查詢到文檔，並提取學生的名字
                let data = document.data()
                let studentName = data?["name"] as? String
                completion(studentName, nil)
            } else {
                // 文檔不存在
                completion(nil, nil)
            }
        }
    }
}
