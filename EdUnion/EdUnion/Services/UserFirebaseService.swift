//
//  UserFirebaseService.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/14.
//

import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

protocol UserProtocol {
    var id: String { get set }
    var fullName: String { get }
    var photoURL: String? { get }
}

class UserFirebaseService {
    static let shared = UserFirebaseService()
    private init() {}
    
    let db = Firestore.firestore()
    let storage = Storage.storage()
    
    let userID = UserSession.shared.currentUserID ?? ""
    
    // MARK: - 通用查詢方法
    func fetchData<T: Decodable>(from collection: String, by id: String, as type: T.Type, completion: @escaping (Result<T, Error>) -> Void) {
            db.collection(collection).document(id).getDocument { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                } else if let data = try? snapshot?.data(as: type) {
                    completion(.success(data))
                } else {
                    completion(.failure(NSError(domain: "No data found in \(collection)", code: 404, userInfo: nil)))
                }
            }
        }
    func fetchUser<T: UserProtocol & Decodable>(from collection: String, by id: String, as type: T.Type, completion: @escaping (Result<T, Error>) -> Void) {
        db.collection(collection).document(id).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
            } else if var data = try? snapshot?.data(as: type) {
                // 設置文檔 ID
                data.id = snapshot?.documentID ?? ""
                completion(.success(data))
            } else {
                completion(.failure(NSError(domain: "No data found in \(collection)", code: 404, userInfo: nil)))
            }
        }
    }
        // 調用泛型方法來獲取老師資料
//        func fetchTeacher(by id: String, completion: @escaping (Result<Teacher, Error>) -> Void) {
//            fetchData(from: "teachers", by: id, as: Teacher.self, completion: completion)
//        }
//        
//        // 調用泛型方法來獲取學生資料
//        func fetchStudent(by id: String, completion: @escaping (Result<Student, Error>) -> Void) {
//            fetchData(from: "students", by: id, as: Student.self, completion: completion)
//        }
    
    // 在 UserFirebaseService 中新增方法
    func fetchFollowedTeachers(forStudentID studentID: String, completion: @escaping (Result<[Teacher], Error>) -> Void) {
        // 首先根據學生 ID 獲取 followList
        db.collection("students").document(studentID).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = snapshot?.data(), let followList = data["followList"] as? [String] {
                self.fetchTeachers(for: followList, completion: completion)
            } else {
                completion(.failure(NSError(domain: "Invalid followList", code: 404, userInfo: nil)))
            }
        }
    }
    
    func fetchFrequentlyUsedTeachers(forStudentID studentID: String, completion: @escaping (Result<[Teacher], Error>) -> Void) {
        // 首先根據學生 ID 獲取 followList
        db.collection("students").document(studentID).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = snapshot?.data(), let usedList = data["usedList"] as? [String] {
                // 查詢 followList 中的所有老師
                self.fetchTeachers(for: usedList, completion: completion)
            } else {
                completion(.failure(NSError(domain: "Invalid usedList", code: 404, userInfo: nil)))
            }
        }
    }
    
    func getStudentFollowList(studentID: String, completion: @escaping ([String]?, Error?) -> Void) {
        let studentRef = db.collection("students").document(studentID)
        
        studentRef.getDocument { document, error in
            if let error = error {
                completion(nil, error)
            } else if let document = document, document.exists {
                let followList = document.data()?["followList"] as? [String] ?? []
                completion(followList, nil)
            } else {
                completion([], nil)
            }
        }
    }
    
    func removeTeacherFromFollowList(studentID: String, teacherID: String, completion: @escaping (Error?) -> Void) {
        let studentRef = db.collection("students").document(studentID)
        
        studentRef.updateData([
            "followList": FieldValue.arrayRemove([teacherID])
        ]) { error in
            completion(error)
        }
    }
    
    func updateStudentList(studentID: String, teacherID: String, listName: String, completion: @escaping (Error?) -> Void) {
        let studentRef = db.collection("students").document(studentID)
        
        studentRef.updateData([
            listName: FieldValue.arrayUnion([teacherID])
        ]) { error in
            if let error = error {
                print("更新 \(listName) 時出錯: \(error.localizedDescription)")
                completion(error)
            } else {
                print("成功添加老師到 \(listName)")
                completion(nil)  // 更新成功
            }
        }
    }
    
    //    func updateStudentFollowList(studentID: String, teacherID: String, completion: @escaping (Error?) -> Void) {
    //            let studentRef = db.collection("students").document(studentID)
    //
    //            studentRef.updateData([
    //                "followList": FieldValue.arrayUnion([teacherID])
    //            ]) { error in
    //                if let error = error {
    //                    print("更新 followList 時出錯: \(error.localizedDescription)")
    //                    completion(error)
    //                } else {
    //                    print("成功添加老師到 followList")
    //                    completion(nil)  // 更新成功
    //                }
    //            }
    //        }
    
    // 查詢 followList 中的所有老師資料
    private func fetchTeachers(for ids: [String], completion: @escaping (Result<[Teacher], Error>) -> Void) {
        var teachers: [Teacher] = []
        let group = DispatchGroup() 
        
        for id in ids {
            group.enter()
            db.collection("teachers").document(id).getDocument { snapshot, error in
                if let error = error {
                    print("Error fetching teacher with id \(id): \(error)")
                } else if var teacher = try? snapshot?.data(as: Teacher.self) {
                    teacher.id = snapshot?.documentID ?? ""
                    teachers.append(teacher)
                }
                group.leave()
            }
        }
        
        // 當所有查詢完成後回傳結果
        group.notify(queue: .main) {
            if !teachers.isEmpty {
                completion(.success(teachers))
            } else {
                completion(.failure(NSError(domain: "No teachers found", code: 404, userInfo: nil)))
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
    func fetchTeachersRealTime(completion: @escaping (Result<[Teacher], Error>) -> Void) -> ListenerRegistration? {
        let teachersRef = db.collection("teachers")
        
        // 添加實時監聽器
        let listener = teachersRef.addSnapshotListener { snapshot, error in
            if let error = error {
                completion(.failure(error))
            } else if let snapshot = snapshot {
                let teachers: [Teacher] = snapshot.documents.compactMap { doc in
                    var teacher = try? doc.data(as: Teacher.self)
                    teacher?.id = doc.documentID
                    return teacher
                }
                completion(.success(teachers))
            }
        }
        
        return listener  // 返回監聽器，稍後可以根據需要移除監聽
    }
    
    func fetchBlocklist(completion: @escaping (Result<[String], Error>) -> Void) {

            let userRef = db.collection("students").document(userID)
            userRef.getDocument { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                } else if let snapshot = snapshot, snapshot.exists {
                    let blocklist = snapshot.data()?["blockList"] as? [String] ?? []
                    completion(.success(blocklist))
                } else {
                    completion(.success([]))
                }
            }
        }
    
    // MARK: - 老師：存可選時段
    func updateTimeSlot(_ timeSlot: AvailableTimeSlot, for teacherID: String, operation: FieldValue, completion: @escaping (Result<Void, Error>) -> Void) {
        let timeSlotData = timeSlot.toDictionary()
        let teacherRef = db.collection("teachers").document(teacherID)
        
        // 先檢查是否有 timeSlots 欄位
        teacherRef.getDocument { document, error in
            if let document = document, document.exists {
                // 如果欄位存在，進行正常操作
                if let timeSlots = document.data()?["timeSlots"] as? [[String: Any]] {
                    // 正常更新 timeSlots 欄位
                    teacherRef.updateData([
                        "timeSlots": operation == .arrayUnion([timeSlotData]) ? FieldValue.arrayUnion([timeSlotData]) : FieldValue.arrayRemove([timeSlotData])
                    ]) { error in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            completion(.success(()))
                        }
                    }
                } else {
                    // 如果 timeSlots 欄位不存在，創建 timeSlots 並執行 arrayUnion 操作
                    teacherRef.setData([
                        "timeSlots": FieldValue.arrayUnion([timeSlotData])
                    ], merge: true) { error in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            completion(.success(()))
                        }
                    }
                }
            } else if let error = error {
                completion(.failure(error))
            }
        }
    }
    
    // 保存時段（新增）
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
                self.saveTimeSlot(newTimeSlot, forTeacher: teacherID, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK - 聊天室
    func fetchChatRooms(for participantID: String, isTeacher: Bool, completion: @escaping ([ChatRoom]?, Error?) -> Void) {
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
                    guard let chatRoom = try? document.data(as: ChatRoom.self) else {
                        return nil
                    }
                    
                    // 根據是否為老師來篩選 participants 的位置
                    if isTeacher {
                        // 如果是老師，檢查 participantID 是否在索引 0
                        if chatRoom.participants.indices.contains(0), chatRoom.participants[0] == participantID {
                            return chatRoom
                        }
                    } else {
                        // 如果是學生，檢查 participantID 是否在索引 1
                        if chatRoom.participants.indices.contains(1), chatRoom.participants[1] == participantID {
                            return chatRoom
                        }
                    }
                    
                    return nil
                }
                
                completion(chatRooms, nil)
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
    
    func fetchMessages(chatRoomID: String, currentUserID: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        db.collection("chats").document(chatRoomID).collection("messages")
            .order(by: "timestamp", descending: false)
            .getDocuments { (snapshot, error) in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                let messages: [Message] = snapshot?.documents.compactMap { doc in
                    return try? doc.data(as: Message.self)
                } ?? []
                
                completion(.success(messages))
            }
        
        addMessageListener(chatRoomID: chatRoomID, currentUserID: currentUserID, completion: completion)
    }
    
    func addMessageListener(chatRoomID: String, currentUserID: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        db.collection("chats").document(chatRoomID).collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { (snapshot, error) in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                let newMessages: [Message] = snapshot?.documentChanges.compactMap { diff in
                    // 只處理新增或更新的消息
                    if diff.type == .added || diff.type == .modified {
                        return try? diff.document.data(as: Message.self)
                    }
                    return nil
                } ?? []
                
                // 傳遞新消息
                completion(.success(newMessages))
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
    
    func fetchName(from collection: String, by id: String, completion: @escaping (Result<String?, Error>) -> Void) {
        let ref = db.collection(collection).document(id)
        ref.getDocument { document, error in
            if let error = error {
                completion(.failure(error))
            } else if let document = document, document.exists {
                let name = document.data()?["fullName"] as? String
                completion(.success(name))
            } else {
                completion(.success(nil))
            }
        }
    }
    
    // MARK: - 封鎖檢舉
    func blockUser(blockID: String, isTeacher: Bool, completion: @escaping (Error?) -> Void) {
        let collectionName = isTeacher ? "teachers" : "students"
        
        let userRef = db.collection(collectionName).document(userID)
        
        userRef.updateData([
            "blockList": FieldValue.arrayUnion([blockID])
        ]) { error in
            completion(error)
        }
    }
    
    func removeStudentFromTeacherNotes(teacherID: String, studentID: String, completion: @escaping (Error?) -> Void) {
            let teacherRef = Firestore.firestore().collection("teachers").document(teacherID)
            teacherRef.updateData([
                "studentsNotes.\(studentID)": FieldValue.delete()
            ]) { error in
                completion(error)
            }
        }
    //    func fetchStudentName(by id: String, completion: @escaping (Result<String?, Error>) -> Void) {
    //        let studentRef = db.collection("students").document(id)
    //        studentRef.getDocument { document, error in
    //            if let error = error {
    //                completion(.failure(error))
    //            } else if let document = document, document.exists {
    //                let studentName = document.data()?["name"] as? String
    //                completion(.success(studentName))
    //            } else {
    //                completion(.success(nil))
    //            }
    //        }
    //    }
    
    
    // MARK: - 日期格式
    //    private let dateFormatter: DateFormatter = {
    //        let formatter = DateFormatter()
    //        formatter.dateFormat = "yyyy-MM-dd"
    //        formatter.timeZone = TimeZone.current
    //        formatter.locale = Locale.current
    //        return formatter
    //    }()
}
