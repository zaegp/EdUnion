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

class UserFirebaseService: UserFirebaseServiceProtocol {
    static let shared = UserFirebaseService()
    private init() {}
    
    let db = Firestore.firestore()
    let storage = Storage.storage()
    
    let userID = UserSession.shared.unwrappedUserID
    
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
                data.id = snapshot?.documentID ?? ""
                completion(.success(data))
            } else {
                completion(.failure(NSError(domain: "No data found in \(collection)", code: 404, userInfo: nil)))
            }
        }
    }
    
    func fetchTeacherList(forStudentID studentID: String, listKey: String, completion: @escaping (Result<[Teacher], Error>) -> Void) {
        db.collection("students").document(studentID).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = snapshot?.data(), let idList = data[listKey] as? [String] {
                self.fetchTeachers(for: idList, completion: completion)
            } else {
                completion(.failure(NSError(domain: "Invalid \(listKey)", code: 404, userInfo: nil)))
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
    
    // MARK: - 學生首頁：更新關注和常用老師列表
    func updateStudentList(studentID: String, teacherID: String, listName: String, add: Bool, completion: @escaping (Error?) -> Void) {
        let studentRef = db.collection("students").document(studentID)
        let operation: FieldValue = add ? FieldValue.arrayUnion([teacherID]) : FieldValue.arrayRemove([teacherID])
        
        studentRef.updateData([
            listName: operation
        ]) { error in
            completion(error)
        }
    }
    
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
        
        group.notify(queue: .main) {
            if !teachers.isEmpty {
                completion(.success(teachers))
            } else {
                completion(.failure(NSError(domain: "No teachers found", code: 404, userInfo: nil)))
            }
        }
    }
    
    func updateStudentNotes(studentID: String, note: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        let teacherRef = db.collection("teachers").document(userID)
        
        teacherRef.getDocument { (document, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let document = document, document.exists else {
                completion(.failure(NSError(domain: "Teacher document not found", code: 404, userInfo: nil)))
                return
            }
            
            var studentsNotes = document.data()?["studentsNotes"] as? [String: String] ?? [:]
            let studentExists = studentsNotes[studentID] != nil
            
            studentsNotes[studentID] = note
            teacherRef.updateData(["studentsNotes": studentsNotes]) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(studentExists))
                }
            }
        }
    }
    
    func fetchTeacherStudentList(teacherID: String, completion: @escaping (Result<[String: String], Error>) -> Void) {
        let teacherRef = db.collection("teachers").document(teacherID)
        
        teacherRef.getDocument { (document, error) in
            if let document = document, document.exists {
                if let studentsNotes = document.data()?["studentsNotes"] as? [String: String] {
                    completion(.success(studentsNotes))
                } else {
                    completion(.success([:]))
                }
            } else if let error = error {
                completion(.failure(error))
            } else {
                completion(.failure(NSError(domain: "Teacher document not found", code: 404, userInfo: nil)))
            }
        }
    }
    
    func fetchStudentNote(studentID: String, completion: @escaping (Result<String?, Error>) -> Void) {
        let teacherRef = db.collection("teachers").document(userID)
        
        teacherRef.getDocument { (document, error) in
            if let document = document, document.exists {
                if let studentsNotes = document.data()?["studentsNotes"] as? [String: String] {
                    let studentNote = studentsNotes[studentID]
                    completion(.success(studentNote))
                } else {
                    completion(.success(nil))
                }
            } else if let error = error {
                completion(.failure(error))
            } else {
                completion(.failure(NSError(domain: "Teacher document not found", code: 404, userInfo: nil)))
            }
        }
    }
    
    // MARK: - 學生：顯示老師資訊
    func fetchTeachersRealTime(completion: @escaping (Result<[Teacher], Error>) -> Void) -> ListenerRegistration? {
        let teachersRef = db.collection("teachers")
        
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
        
        return listener
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
    
    // MARK: - 老師可選時段：新增刪除編輯可選時段
    func modifyTimeSlot(_ timeSlot: AvailableTimeSlot, for teacherID: String, add: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        let timeSlotData = timeSlot.toDictionary()
        let teacherRef = db.collection("teachers").document(teacherID)
        let operation: FieldValue = add ? FieldValue.arrayUnion([timeSlotData]) : FieldValue.arrayRemove([timeSlotData])
        
        teacherRef.updateData([
            "timeSlots": operation
        ]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func updateTimeSlot(oldTimeSlot: AvailableTimeSlot, newTimeSlot: AvailableTimeSlot, forTeacher teacherID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        modifyTimeSlot(oldTimeSlot, for: teacherID, add: false) { result in
            switch result {
            case .success:
                self.modifyTimeSlot(newTimeSlot, for: teacherID, add: true, completion: completion)
            case .failure(let error):
                completion(.failure(error))
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
            "selectedTimeSlots.\(dateString)": colorHex ?? ""
        ]) { error in
            if let error = error {
                print("保存日期顏色時出錯：\(error)")
            } else {
                print("日期顏色成功保存！")
            }
        }
    }
    
    // MARK: - 聊天室
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
                    
                    if isTeacher {
                        if chatRoom.participants.indices.contains(0), chatRoom.participants[0] == participantID {
                            return chatRoom
                        }
                    } else {
                        if chatRoom.participants.indices.contains(1), chatRoom.participants[1] == participantID {
                            return chatRoom
                        }
                    }
                    
                    return nil
                }
                
                completion(chatRooms, nil)
            }
    }
    
    func sendMessage(chatRoomID: String, messageData: [String: Any], completion: @escaping (Error?) -> Void) {
        let messageId = UUID().uuidString
        db.collection("chats").document(chatRoomID).collection("messages").document(messageId).setData(messageData, completion: completion)
    }
    
    func updateMessage(chatRoomID: String, messageId: String, updatedData: [String: Any], completion: @escaping (Error?) -> Void) {
        db.collection("chats").document(chatRoomID).collection("messages").document(messageId).updateData(updatedData, completion: completion)
    }
    
    func uploadPhoto(image: UIImage, messageId: String, completion: @escaping (String?, Error?) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            let conversionError = NSError(domain: "ImageConversionError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to JPEG format."])
            completion(nil, conversionError)
            print("Error: Failed to convert image to JPEG format.")
            return
        }
        
        let storageRef = storage.reference().child("chat_images/\(messageId).jpg")
        
        storageRef.putData(imageData, metadata: nil) { _, error in
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
    
    func fetchMessages(chatRoomID: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        db.collection("chats").document(chatRoomID).collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                } else if let snapshot = snapshot {
                    let messages = snapshot.documents.compactMap { doc in
                        try? doc.data(as: Message.self)
                    }
                    completion(.success(messages))
                }
            }
    }
    
    // 老師：取今日課程
    func fetchTodayConfirmedAppointments(completion: @escaping (Result<[Appointment], Error>) -> Void) {
        let todayDateString = dateFormatter.string(from: Date())
        
        db.collection("appointments")
            .whereField("date", isEqualTo: todayDateString)
            .whereField("status", isEqualTo: "confirmed")
            .getDocuments { querySnapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                let appointments = querySnapshot?.documents.compactMap { doc in
                    try? doc.data(as: Appointment.self)
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
    func blockUser(blockID: String, userCollection: String, completion: @escaping (Error?) -> Void) {
        let userRef = db.collection(userCollection).document(userID)
        
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
    
    // 共通：上傳使用者照片
    func uploadProfileImage(_ image: UIImage, forUserID userID: String, userRole: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let roleFolder = (userRole == "teacher") ? "teacher_images" : "student_images"
        let storageRef = Storage.storage().reference().child("\(roleFolder)/\(userID).jpg")
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "ImageConversionError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Error converting image to data."])))
            return
        }
        
        storageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let downloadURL = url else {
                    completion(.failure(NSError(domain: "DownloadURLError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Download URL is nil."])))
                    return
                }
                
                let collection = (userRole == "teacher") ? "teachers" : "students"
                let userRef = Firestore.firestore().collection(collection).document(userID)
                
                userRef.updateData(["photoURL": downloadURL.absoluteString]) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
            }
        }
    }
    
    // 共通：刪除帳號
    func updateUserStatusToDeleting(userID: String, userRole: String, completion: @escaping (Error?) -> Void) {
        let collection = (userRole == "teacher") ? "teachers" : "students"
        let userRef = Firestore.firestore().collection(collection).document(userID)
        
        userRef.updateData(["status": "Deleting"]) { error in
            completion(error)
        }
    }
}
