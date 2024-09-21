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

    // MARK: - 通用查詢方法
    private func fetchDocuments<T: Decodable>(from collection: String, completion: @escaping (Result<[T], Error>) -> Void) {
        db.collection(collection).getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
            } else {
                let models = snapshot?.documents.compactMap { doc -> T? in
                    return try? doc.data(as: T.self)
                } ?? []
                completion(.success(models))
            }
        }
    }
    
    func updateStudentNotes(forTeacher teacherID: String, studentID: String, note: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        let teacherRef = db.collection("teachers").document(teacherID)
        
        // 使用 Firestore 的 `updateData` 方法更新或創建 studentsNotes 欄位
        teacherRef.getDocument { (document, error) in
            if let document = document, document.exists {
                // 檢查 studentsNotes 欄位是否存在
                if var studentsNotes = document.data()?["studentsNotes"] as? [String: String] {
                    let studentExists = studentsNotes[studentID] != nil  // 檢查 studentID 是否已存在
                    
                    // 更新已有的 studentsNotes
                    studentsNotes[studentID] = note
                    teacherRef.updateData(["studentsNotes": studentsNotes]) { error in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            // 返回 student 是否存在的結果
                            completion(.success(studentExists))
                        }
                    }
                } else {
                    // 如果欄位不存在，創建它並返回 student 不存在
                    let newNotes = [studentID: note]
                    teacherRef.updateData(["studentsNotes": newNotes]) { error in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            // 返回 student 不存在，因為是新創建的
                            completion(.success(false))
                        }
                    }
                }
            } else if let error = error {
                // 如果獲取老師文檔時出現錯誤
                completion(.failure(error))
            } else {
                // 如果文檔不存在
                completion(.failure(NSError(domain: "Teacher document not found", code: 404, userInfo: nil)))
            }
        }
    }
    
    func fetchTeacherStudentList(teacherID: String, completion: @escaping (Result<[String: String], Error>) -> Void) {
            let teacherRef = db.collection("teachers").document(teacherID)
            
            teacherRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    // 取出 studentsNotes 欄位
                    if let studentsNotes = document.data()?["studentsNotes"] as? [String: String] {
                        completion(.success(studentsNotes))
                    } else {
                        completion(.success([:]))  // 如果 studentsNotes 不存在，返回空字典
                    }
                } else if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.failure(NSError(domain: "Teacher document not found", code: 404, userInfo: nil)))
                }
            }
        }
    
    func fetchStudentNote(teacherID: String, studentID: String, completion: @escaping (Result<String?, Error>) -> Void) {
            let teacherRef = db.collection("teachers").document(teacherID)
            
            teacherRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    // 取出 studentsNotes 欄位
                    if let studentsNotes = document.data()?["studentsNotes"] as? [String: String] {
                        // 查找特定學生的備註
                        let studentNote = studentsNotes[studentID]
                        completion(.success(studentNote))  // 如果找到，返回備註
                    } else {
                        completion(.success(nil))  // 如果沒有找到該學生，返回 nil
                    }
                } else if let error = error {
                    completion(.failure(error))  // 發生錯誤時返回錯誤信息
                } else {
                    completion(.failure(NSError(domain: "Teacher document not found", code: 404, userInfo: nil)))
                }
            }
        }

    // MARK: - 學生：顯示老師資訊
    func fetchTeachers(completion: @escaping (Result<[Teacher], Error>) -> Void) {
        fetchDocuments(from: "teachers", completion: completion)
    }
    
    // MARK: - 老師：存可選時段
    func updateTimeSlot(_ timeSlot: AvailableTimeSlot, for teacherID: String, operation: FieldValue, completion: @escaping (Result<Void, Error>) -> Void) {
        let timeSlotData = timeSlot.toDictionary()
        let teacherRef = db.collection("teachers").document(teacherID)
        
        teacherRef.updateData([
            "timeSlots": operation == .arrayUnion([timeSlotData]) ? FieldValue.arrayUnion([timeSlotData]) : FieldValue.arrayRemove([timeSlotData])
        ]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    // 保存時段（新增）
    func saveTimeSlot(_ timeSlot: AvailableTimeSlot, for teacherID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        updateTimeSlot(timeSlot, for: teacherID, operation: .arrayUnion([timeSlot.toDictionary()]), completion: completion)
    }
    
    // 刪除時段
    func deleteTimeSlot(_ timeSlot: AvailableTimeSlot, for teacherID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        updateTimeSlot(timeSlot, for: teacherID, operation: .arrayRemove([timeSlot.toDictionary()]), completion: completion)
    }
    
    // MARK: - 老師：取可選時段
    func fetchTimeSlots(forTeacher teacherID: String, completion: @escaping (Result<[AvailableTimeSlot], Error>) -> Void) {
        let teacherRef = db.collection("teachers").document(teacherID)
        teacherRef.getDocument { (documentSnapshot, error) in
            if let error = error {
                completion(.failure(error))
            } else if let document = documentSnapshot, document.exists {
                let timeSlotsData = document.data()?["timeSlots"] as? [[String: Any]] ?? []
                let timeSlots = timeSlotsData.compactMap { AvailableTimeSlot.fromDictionary($0) }
                completion(.success(timeSlots))
            } else {
                completion(.success([]))
            }
        }
    }

    // MARK: - 老師：存日期顏色對應
    func saveDateColorToFirebase(date: Date, color: Color, teacherID: String) {
        let colorHex = color.toHex()
        let dateString = dateFormatter.string(from: date)
        let teacherRef = db.collection("teachers").document(teacherID)
        
        teacherRef.updateData([
            "selectedTimeSlots.\(dateString)": colorHex
        ]) { error in
            if let error = error {
                print("保存日期顏色時出錯：\(error)")
            } else {
                print("日期顏色成功保存！")
            }
        }
    }
    
    // MARK: - 更新時間段（舊換新）
    func updateTimeSlot(oldTimeSlot: AvailableTimeSlot, newTimeSlot: AvailableTimeSlot, forTeacher teacherID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        deleteTimeSlot(oldTimeSlot, for: teacherID) { result in
            switch result {
            case .success:
                self.saveTimeSlot(newTimeSlot, for: teacherID, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK - 聊天室
    func fetchChatRooms(for participantID: String, completion: @escaping (Result<[ChatRoom], Error>) -> Void) {
        db.collection("chats")
            .whereField("participants", arrayContains: participantID)
            .order(by: "lastMessageTimestamp", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                let chatRooms: [ChatRoom] = snapshot?.documents.compactMap {
                    return ChatRoom(id: $0.documentID, data: $0.data())
                } ?? []
                completion(.success(chatRooms))
            }
    }
    
    // 發送訊息
    func sendMessage(chatRoomID: String, messageData: [String: Any], completion: @escaping (Error?) -> Void) {
        let messageId = UUID().uuidString
        db.collection("chats").document(chatRoomID).collection("messages").document(messageId).setData(messageData, completion: completion)
    }
    
    // 更新訊息
    func updateMessage(chatRoomID: String, messageId: String, updatedData: [String: Any], completion: @escaping (Error?) -> Void) {
        db.collection("chats").document(chatRoomID).collection("messages").document(messageId).updateData(updatedData, completion: completion)
    }
    
    // 上傳照片
    func uploadPhoto(image: UIImage, messageId: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            let conversionError = NSError(domain: "ImageConversionError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to JPEG format."])
            completion(.failure(conversionError))
            return
        }
        
        let storageRef = storage.reference().child("chat_images/\(messageId).jpg")
        
        storageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                } else if let urlString = url?.absoluteString {
                    completion(.success(urlString))
                } else {
                    let urlError = NSError(domain: "DownloadURLError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to generate download URL."])
                    completion(.failure(urlError))
                }
            }
        }
    }

    // 上傳音檔
    func uploadAudio(audioData: Data, audioId: String, completion: @escaping (Result<String, Error>) -> Void) {
        let storageRef = storage.reference().child("chat_audio/\(audioId).m4a")
        
        storageRef.putData(audioData, metadata: nil) { _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            storageRef.downloadURL { url, error in
                if let urlString = url?.absoluteString {
                    completion(.success(urlString))
                } else {
                    completion(.failure(error!))
                }
            }
        }
    }
    
    // 取消息
    func fetchMessages(chatRoomID: String, currentUserID: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        db.collection("chats").document(chatRoomID).collection("messages")
            .order(by: "timestamp", descending: false)
            .getDocuments { (snapshot, error) in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                let messages: [Message] = snapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    return Message(
                        ID: data["ID"] as? String ?? doc.documentID,
                        type: data["type"] as? Int ?? 0,
                        content: data["content"] as? String ?? "",
                        senderID: data["senderID"] as? String ?? "",
                        isSentByCurrentUser: data["senderID"] as? String == currentUserID,
                        isSeen: data["isSeen"] as? Bool ?? false,
                        timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                    )
                } ?? []
                completion(.success(messages))
                
                // 添加消息監聽器
                self.addMessageListener(chatRoomID: chatRoomID, currentUserID: currentUserID, completion: completion)
            }
    }
    
    // 添加消息監聽器
    func addMessageListener(chatRoomID: String, currentUserID: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        db.collection("chats").document(chatRoomID).collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                let messages: [Message] = snapshot?.documentChanges.compactMap { diff in
                    if diff.type == .added || diff.type == .modified {
                        let data = diff.document.data()
                        return Message(
                            ID: data["ID"] as? String ?? diff.document.documentID,
                            type: data["type"] as? Int ?? 0,
                            content: data["content"] as? String ?? "",
                            senderID: data["senderID"] as? String ?? "",
                            isSentByCurrentUser: data["senderID"] as? String == currentUserID,
                            isSeen: data["isSeen"] as? Bool ?? false,
                            timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                        )
                    }
                    return nil
                } ?? []
                completion(.success(messages))
            }
    }
    
    // 老師：取今日課程
    func fetchTodayConfirmedAppointments(completion: @escaping (Result<[Appointment], Error>) -> Void) {
        let todayDate = Date()
        let todayDateString = dateFormatter.string(from: todayDate)
        
        db.collection("appointments")
            .whereField("date", isEqualTo: todayDateString)
            .whereField("status", isEqualTo: "confirmed")
            .getDocuments { querySnapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                let appointments = querySnapshot?.documents.compactMap { doc in
                    return try? doc.data(as: Appointment.self)
                } ?? []
                completion(.success(appointments))
            }
    }
    
    // 使用者 ID 搜名字
    func fetchStudentName(by id: String, completion: @escaping (Result<String?, Error>) -> Void) {
        let studentRef = db.collection("students").document(id)
        studentRef.getDocument { document, error in
            if let error = error {
                completion(.failure(error))
            } else if let document = document, document.exists {
                let studentName = document.data()?["name"] as? String
                completion(.success(studentName))
            } else {
                completion(.success(nil))
            }
        }
    }
    
    // MARK: - 日期格式
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale.current
        return formatter
    }()
}
