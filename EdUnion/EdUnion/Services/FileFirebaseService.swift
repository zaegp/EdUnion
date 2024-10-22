//
//  FileFirebaseService.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/10/18.
//

//import Foundation
//import FirebaseStorage
//import FirebaseFirestore
//
//
//class FileFirebaseService {
//    static let shared = FileFirebaseService()
//        private let storage = Storage.storage()
//        private let firestore = Firestore.firestore()
//    var files: [FileItem] = []
//    
//    var currentUploadTask: StorageUploadTask?
//        
//        private init() {}
//    
//    func uploadFileToFirebase(_ fileURL: URL, fileName: String, retryCount: Int = 3, completion: @escaping (Result<String, Error>) -> Void) {
//        guard let currentUserID = UserSession.shared.currentUserID else {
//            print("Error: Current user ID is nil.")
//            completion(.failure(NSError(domain: "UserSession", code: -1, userInfo: [NSLocalizedDescriptionKey: "Current user ID is nil."])))
//            return
//        }
//        
//        guard fileURL.startAccessingSecurityScopedResource() else {
//            print("无法访问安全范围资源")
//            completion(.failure(NSError(domain: "FileAccess", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法访问安全范围资源"])))
//            return
//        }
//        defer {
//            fileURL.stopAccessingSecurityScopedResource()
//        }
//        
//        // Step 1: Copy the file to the app's cache directory
//        let cacheDirectory = getCacheDirectory()
//        let cachedFileURL = cacheDirectory.appendingPathComponent(fileName)
//        do {
//            if FileManager.default.fileExists(atPath: cachedFileURL.path) {
//                try FileManager.default.removeItem(at: cachedFileURL)
//            }
//            try FileManager.default.copyItem(at: fileURL, to: cachedFileURL)
//            print("成功复制文件到缓存目录：\(cachedFileURL.path)")
//        } catch {
//            print("Error copying file to cache directory: \(error.localizedDescription)")
//            completion(.failure(error))
//            return
//        }
//        
//        let storagePath = "files/\(fileName)"
//        let storageRef = storage.reference().child(storagePath)
//        
//        do {
//            let fileData = try Data(contentsOf: cachedFileURL)
//            let metadata = StorageMetadata()
//            metadata.contentType = "application/octet-stream"
//            metadata.customMetadata = ["ownerId": currentUserID]
//            
//            print("Starting upload for file: \(fileName)")
////            showActivityIndicator()
//            
//            let uploadTask = storageRef.putData(fileData, metadata: metadata) { metadata, error in
////                self.hideActivityIndicator()
//                if let error = error {
//                    print("Upload failed with error: \(error.localizedDescription)")
//                    print("Error details: \(error)")
//                    completion(.failure(error))
//                    return
//                }
//                
//                print("Upload completed, fetching download URL.")
//                
//                storageRef.downloadURL { url, error in
//                    if let error = error {
//                        print("Download URL fetch failed with error: \(error.localizedDescription)")
//                        completion(.failure(error))
//                    } else if let url = url {
//                        print("Upload successful. Download URL: \(url.absoluteString)")
//                        
//                        // 保存文件元数据到 Firestore
//                        self.saveFileMetadataToFirestore(downloadURL: url.absoluteString, storagePath: storagePath, fileName: fileName, ownerID: currentUserID) { result in
//                            switch result {
//                            case .success:
//                                print("文件元数据保存成功")
//                            case .failure(let error):
//                                print("保存文件元数据时出错：\(error.localizedDescription)")
//                            }
//                        }
//                        
//                        // Step 2: 创建新的 FileItem 并添加到 files 数组
//                        let newFileItem = FileItem(localURL: cachedFileURL, remoteURL: url, downloadURL: url.absoluteString, fileName: fileName, storagePath: storagePath)
//                        DispatchQueue.main.async {
//                            self.files.append(newFileItem)
//                            self.collectionView.reloadData()
//                        }
//                        
//                        completion(.success(url.absoluteString))
//                    }
//                }
//            }
//            
//            uploadTask.observe(StorageTaskStatus.progress) { snapshot in
//                if let progress = snapshot.progress {
//                    let percentComplete = 100.0 * Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
//                    DispatchQueue.main.async {
//                    }
//                }
//            }
//            
//            uploadTask.observe(StorageTaskStatus.failure) { snapshot in
//                if let error = snapshot.error {
//                    print("Upload failed during progress update: \(error.localizedDescription)")
//                    print("Error details: \(error)")
//                    completion(.failure(error))
//                }
//            }
//            
//            self.currentUploadTask = uploadTask
//        } catch {
//            print("Error reading file data: \(error.localizedDescription)")
//            completion(.failure(error))
//        }
//    }
//    
//    func fetchUserFiles() {
//        guard let currentUserID = UserSession.shared.currentUserID else {
//            print("Error: Current user ID is nil.")
//            setCustomEmptyStateView() // 顯示自定義的 empty state
//            return
//        }
//        
//        let cachedFiles = getCachedFiles()
//        if !cachedFiles.isEmpty {
//            self.files = cachedFiles
//            DispatchQueue.main.async {
//                self.collectionView.reloadData()
//                self.restoreCollectionView() // 恢復正常背景
//            }
//            // 如果有緩存的文件，暫時不設置監聽器
//            return
//        } else {
//            setCustomEmptyStateView()
//        }
//        
//        setupFirestoreListener(for: currentUserID)
//    }
//    
//    func saveFileMetadataToFirestore(downloadURL: String, storagePath: String, fileName: String, ownerID: String, completion: @escaping (Result<Void, Error>) -> Void) {
//            let fileData: [String: Any] = [
//                "fileName": fileName,
//                "downloadURL": downloadURL,
//                "storagePath": storagePath,
//                "createdAt": Timestamp(),
//                "ownerID": ownerID,
//                "authorizedStudents": []
//            ]
//            
//            firestore.collection("files").addDocument(data: fileData) { error in
//                if let error = error {
//                    print("保存文件元数据失败：\(error.localizedDescription)")
//                    completion(.failure(error))
//                } else {
//                    print("文件元数据保存成功")
//                    completion(.success(()))
//                }
//            }
//        }
//    
//    func deleteFileFromStorage(storagePath: String, completion: @escaping (Result<Void, Error>) -> Void) {
//            let storageRef = storage.reference().child(storagePath)
//            
//            storageRef.delete { error in
//                if let error = error {
//                    print("删除 Storage 文件失败：\(error.localizedDescription)")
//                    completion(.failure(error))
//                } else {
//                    print("Storage 文件删除成功")
//                    completion(.success(()))
//                }
//            }
//        }
//        
//        /// 删除 Firestore 中的文件元数据
//        /// - Parameters:
//        ///   - storagePath: 文件在 Storage 中的路径（用于查找元数据）
//        ///   - completion: 删除完成的回调
//        func deleteFileMetadata(storagePath: String, completion: @escaping (Result<Void, Error>) -> Void) {
//            firestore.collection("files")
//                .whereField("storagePath", isEqualTo: storagePath)
//                .getDocuments { snapshot, error in
//                    if let error = error {
//                        print("获取文件元数据失败：\(error.localizedDescription)")
//                        completion(.failure(error))
//                        return
//                    }
//                    
//                    guard let document = snapshot?.documents.first else {
//                        print("未找到对应的文件元数据")
//                        completion(.failure(NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "未找到对应的文件元数据"])))
//                        return
//                    }
//                    
//                    document.reference.delete { error in
//                        if let error = error {
//                            print("删除文件元数据失败：\(error.localizedDescription)")
//                            completion(.failure(error))
//                        } else {
//                            print("文件元数据删除成功")
//                            completion(.success(()))
//                        }
//                    }
//                }
//        }
//        
//        // MARK: - Fetch Files
//        
//        /// 获取当前用户的文件列表
//        /// - Parameters:
//        ///   - userID: 当前用户的 ID
//        ///   - userRole: 用户角色（老师或学生）
//        ///   - completion: 获取完成的回调
//        func fetchUserFiles(userID: String, userRole: UserRole, completion: @escaping (Result<[FileItem], Error>) -> Void) {
//            let collectionPath = "files"
//            let queryField = userRole == .teacher ? "ownerID" : "authorizedStudents"
//            
//            let query: Query = userRole == .teacher ?
//                firestore.collection(collectionPath).whereField(queryField, isEqualTo: userID) :
//                firestore.collection(collectionPath).whereField(queryField, arrayContains: userID)
//            
//            query.getDocuments { snapshot, error in
//                if let error = error {
//                    print("获取用户文件失败：\(error.localizedDescription)")
//                    completion(.failure(error))
//                    return
//                }
//                
//                var fileItems: [FileItem] = []
//                snapshot?.documents.forEach { document in
//                    let data = document.data()
//                    if let downloadURL = data["downloadURL"] as? String,
//                       let fileName = data["fileName"] as? String,
//                       let storagePath = data["storagePath"] as? String,
//                       let remoteURL = URL(string: downloadURL) {
//                        
//                        let fileItem = FileItem(localURL: nil, remoteURL: remoteURL, downloadURL: downloadURL, fileName: fileName, storagePath: storagePath)
//                        fileItems.append(fileItem)
//                    }
//                }
//                
//                completion(.success(fileItems))
//            }
//        }
//        
//        // MARK: - Update File Metadata
//        
//        /// 更新文件的元数据，例如文件名
//        /// - Parameters:
//        ///   - storagePath: 文件在 Storage 中的路径
//        ///   - newFileName: 新的文件名
//        ///   - completion: 更新完成的回调
//        func updateFileName(storagePath: String, newFileName: String, completion: @escaping (Result<Void, Error>) -> Void) {
//            firestore.collection("files")
//                .whereField("storagePath", isEqualTo: storagePath)
//                .getDocuments { snapshot, error in
//                    if let error = error {
//                        print("获取文件元数据失败：\(error.localizedDescription)")
//                        completion(.failure(error))
//                        return
//                    }
//                    
//                    guard let document = snapshot?.documents.first else {
//                        print("未找到对应的文件元数据")
//                        completion(.failure(NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "未找到对应的文件元数据"])))
//                        return
//                    }
//                    
//                    document.reference.updateData(["fileName": newFileName]) { error in
//                        if let error = error {
//                            print("更新文件名失败：\(error.localizedDescription)")
//                            completion(.failure(error))
//                        } else {
//                            print("文件名更新成功")
//                            completion(.success(()))
//                        }
//                    }
//                }
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
//}
