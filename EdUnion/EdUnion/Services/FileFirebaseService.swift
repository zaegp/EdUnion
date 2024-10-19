//
//  FileFirebaseService.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/10/18.
//

//import FirebaseStorage
//import FirebaseFirestore
//
//class FileFirebaseService {
//    static let shared = FileFirebaseService()
//    static let storage = Storage.storage()
//    static let firestore = Firestore.firestore()
//    let userID = UserSession.shared.unwrappedUserID
//    
//    private init() {}
//    
//    // MARK: - File Operations
//    
//    func fetchUserFiles(userRole: UserRole, completion: @escaping (Result<[FileItem], Error>) -> Void) {
//        
//        let collectionPath = "files"
//        let queryField = userRole == .teacher ? "ownerID" : "authorizedStudents"
//        
//        let query: Query
//        if userRole == .teacher {
//            query = FileFirebaseService.firestore.collection(collectionPath).whereField(queryField, isEqualTo: userID)
//        } else {
//            query = FileFirebaseService.firestore.collection(collectionPath).whereField(queryField, arrayContains: userID)
//        }
//        
//        query.getDocuments { snapshot, error in
//            if let error = error {
//                completion(.failure(error))
//                return
//            }
//            
//            guard let documents = snapshot?.documents else {
//                completion(.success([]))
//                return
//            }
//            
//            var files: [FileItem] = []
//            
//            for document in documents {
//                guard let urlString = document.data()["downloadURL"] as? String,
//                      let fileName = document.data()["fileName"] as? String,
//                      let remoteURL = URL(string: urlString) else {
//                    continue
//                }
//                
//                let storagePath = document.data()["storagePath"] as? String ?? "files/\(fileName)"
//                let fileItem = FileItem(localURL: nil, remoteURL: remoteURL, downloadURL: urlString, fileName: fileName, storagePath: storagePath)
//                files.append(fileItem)
//            }
//            
//            completion(.success(files))
//        }
//    }
//    
//    func uploadFile(fileURL: URL, fileName: String, completion: @escaping (Result<String, Error>) -> Void) {
//        
//        let storagePath = "files/\(fileName)"
//        let storageRef = FileFirebaseService.storage.reference().child(storagePath)
//        
//        do {
//            let fileData = try Data(contentsOf: fileURL)
//            let metadata = StorageMetadata()
//            metadata.contentType = "application/octet-stream"
//            metadata.customMetadata = ["ownerId": userID]
//            
//            storageRef.putData(fileData, metadata: metadata) { metadata, error in
//                if let error = error {
//                    completion(.failure(error))
//                    return
//                }
//                
//                storageRef.downloadURL { url, error in
//                    if let error = error {
//                        completion(.failure(error))
//                        return
//                    }
//                    
//                    guard let downloadURL = url else {
//                        completion(.failure(NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Download URL is nil."])))
//                        return
//                    }
//                    
//                    // Save metadata to Firestore
//                    self.saveFileMetadataToFirestore(downloadURL: downloadURL.absoluteString, storagePath: storagePath, fileName: fileName) { result in
//                        switch result {
//                        case .success:
//                            completion(.success(downloadURL.absoluteString))
//                        case .failure(let error):
//                            completion(.failure(error))
//                        }
//                    }
//                }
//            }
//        } catch {
//            completion(.failure(error))
//        }
//    }
//    
//    private func saveFileMetadataToFirestore(downloadURL: String, storagePath: String, fileName: String, completion: @escaping (Result<Void, Error>) -> Void) {
//        
//        
//        let fileData: [String: Any] = [
//            "fileName": fileName,
//            "downloadURL": downloadURL,
//            "storagePath": storagePath,
//            "createdAt": Timestamp(),
//            "ownerID": userID,
//            "authorizedStudents": []
//        ]
//        
//        FileFirebaseService.firestore.collection("files").addDocument(data: fileData) { error in
//            if let error = error {
//                completion(.failure(error))
//            } else {
//                completion(.success(()))
//            }
//        }
//    }
//    
//    func updateFileMetadata(for fileItem: FileItem, newFileName: String, completion: @escaping (Result<Void, Error>) -> Void) {
//        FileFirebaseService.firestore.collection("files")
//            .whereField("downloadURL", isEqualTo: fileItem.downloadURL)
//            .getDocuments { snapshot, error in
//                if let error = error {
//                    completion(.failure(error))
//                    return
//                }
//                
//                guard let document = snapshot?.documents.first else {
//                    completion(.failure(NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "File not found in Firestore."])))
//                    return
//                }
//                
//                document.reference.updateData(["fileName": newFileName]) { error in
//                    if let error = error {
//                        completion(.failure(error))
//                    } else {
//                        completion(.success(()))
//                    }
//                }
//            }
//    }
//    
//    // MARK: - User Operations
//    
//    func fetchUserData<T: UserProtocol & Decodable>(from collection: String, userID: String, as type: T.Type, completion: @escaping (Result<T, Error>) -> Void) {
//        FileFirebaseService.firestore.collection(collection).document(userID).getDocument { snapshot, error in
//            if let error = error {
//                completion(.failure(error))
//                return
//            }
//            
//            guard let data = snapshot?.data(),
//                  let user = try? Firestore.Decoder().decode(type, from: data) else {
//                completion(.failure(NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode user data."])))
//                return
//            }
//            
//            completion(.success(user))
//        }
//    }
//    
//    // MARK: - File Download
//    
//    func downloadFile(from url: URL, to destinationURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
//        let storageRef = FileFirebaseService.storage.reference(forURL: url.absoluteString)
//        
//        storageRef.write(toFile: destinationURL) { url, error in
//            if let error = error {
//                completion(.failure(error))
//                return
//            }
//            
//            guard let url = url else {
//                completion(.failure(NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Downloaded file URL is nil."])))
//                return
//            }
//            
//            completion(.success(url))
//        }
//    }
//    
//    func authorizeStudents(for fileName: [String], studentIDs: [String], completion: @escaping (Result<Void, Error>) -> Void) {
//        FileFirebaseService.firestore.collection("files")
//            .whereField("fileName", isEqualTo: fileName)
//            .getDocuments { snapshot, error in
//                if let error = error {
//                    completion(.failure(error))
//                    return
//                }
//                
//                guard let document = snapshot?.documents.first else {
//                    let error = NSError(domain: "FileFirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "File not found in Firestore."])
//                    completion(.failure(error))
//                    return
//                }
//                
//                document.reference.updateData([
//                    "authorizedStudents": FieldValue.arrayUnion(studentIDs)
//                ]) { error in
//                    if let error = error {
//                        completion(.failure(error))
//                    } else {
//                        completion(.success(()))
//                    }
//                }
//            }
//    }
//    
//    func fetchStudentsNotes(forTeacherID teacherID: String, completion: @escaping ([String: String]) -> Void) {
//        FileFirebaseService.firestore.collection("teachers").document(teacherID).getDocument { (snapshot, error) in
//            if let error = error {
//                print("Error fetching studentsNotes: \(error.localizedDescription)")
//                completion([:])
//                return
//            }
//            
//            guard let data = snapshot?.data(), let studentsNotes = data["studentsNotes"] as? [String: String] else {
//                print("No studentsNotes found for teacher \(teacherID)")
//                completion([:])
//                return
//            }
//            
//            completion(studentsNotes)
//        }
//    }
//    
//    func uploadFileToFirebase(_ fileURL: URL, fileName: String, retryCount: Int = 3, completion: @escaping (Result<String, Error>) -> Void) {
//            guard let currentUserID = UserSession.shared.currentUserID else {
//                completion(.failure(NSError(domain: "UserSession", code: -1, userInfo: [NSLocalizedDescriptionKey: "Current user ID is nil."])))
//                return
//            }
//
//            // Step 1: 將文件複製到應用程式的緩存目錄
//            let cacheDirectory = getCacheDirectory()
//            let cachedFileURL = cacheDirectory.appendingPathComponent(fileName)
//            do {
//                if FileManager.default.fileExists(atPath: cachedFileURL.path) {
//                    try FileManager.default.removeItem(at: cachedFileURL)
//                }
//                try FileManager.default.copyItem(at: fileURL, to: cachedFileURL)
//            } catch {
//                completion(.failure(error))
//                return
//            }
//
//            let storagePath = "files/\(fileName)"
//        let storageRef = FileFirebaseService.storage.reference().child(storagePath)
//
//            do {
//                let fileData = try Data(contentsOf: cachedFileURL)
//                let metadata = StorageMetadata()
//                metadata.contentType = "application/octet-stream"
//                metadata.customMetadata = ["ownerId": currentUserID]
//
//                let uploadTask = storageRef.putData(fileData, metadata: metadata) { metadata, error in
//                    if let error = error {
//                        if retryCount > 0 {
//                            self.uploadFileToFirebase(cachedFileURL, fileName: fileName, retryCount: retryCount - 1, completion: completion)
//                        } else {
//                            completion(.failure(error))
//                        }
//                        return
//                    }
//
//                    storageRef.downloadURL { url, error in
//                        if let error = error {
//                            if retryCount > 0 {
//                                print("Download URL fetch failed, retrying... (\(retryCount) retries left)")
//                                self.uploadFileToFirebase(cachedFileURL, fileName: fileName, retryCount: retryCount - 1, completion: completion)
//                            } else {
//                                print("Download URL fetch failed with error: \(error.localizedDescription)")
//                                completion(.failure(error))
//                            }
//                        } else if let url = url {
//                            print("Upload successful. Download URL: \(url.absoluteString)")
//                            
//                            // 保存文件元数据到 Firestore
//                            self.saveFileMetadataToFirestore(downloadURL: url.absoluteString, storagePath: storagePath, fileName: fileName) { result in
//                                switch result {
//                                case .success:
//                                    // 文件元数据保存成功，進一步處理
//                                    completion(.success(url.absoluteString))
//                                case .failure(let error):
//                                    // 保存文件元数据失敗
//                                    completion(.failure(error))
//                                }
//                            }
//                        }
//                    }
//                }
//
//                uploadTask.observe(.progress) { snapshot in
//                    if let progress = snapshot.progress {
//                        let percentComplete = 100.0 * Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
//                        DispatchQueue.main.async {
//                            // 更新進度
//                        }
//                    }
//                }
//
//                uploadTask.observe(.failure) { snapshot in
//                    if let error = snapshot.error {
//                        completion(.failure(error))
//                    }
//                }
//
//            } catch {
//                completion(.failure(error))
//            }
//        }
//    
//    func getCacheDirectory() -> URL {
//            let fileManager = FileManager.default
//            let cacheDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("FileCache")
//            
//            if !fileManager.fileExists(atPath: cacheDirectory.path) {
//                do {
//                    try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true, attributes: nil)
//                } catch {
//                    print("Error creating cache directory: \(error.localizedDescription)")
//                }
//            }
//            
//            return cacheDirectory
//        }
//    
//    func updateFileMetadataInFirestore(for fileItem: FileItem, newFileName: String) {
//        FileFirebaseService.firestore.collection("files")
//            .whereField("downloadURL", isEqualTo: fileItem.downloadURL)
//            .getDocuments { snapshot, error in
//                if let error = error {
//                    print("Error finding file in Firestore: \(error.localizedDescription)")
//                    return
//                }
//                
//                guard let document = snapshot?.documents.first else {
//                    print("File not found in Firestore.")
//                    return
//                }
//                
//                // 更新 Firestore 中的文件名
//                document.reference.updateData(["fileName": newFileName]) { error in
//                    if let error = error {
//                        print("Error updating file name in Firestore: \(error.localizedDescription)")
//                    } else {
//                        print("File name successfully updated in Firestore.")
//                    }
//                }
//            }
//    }
//}
