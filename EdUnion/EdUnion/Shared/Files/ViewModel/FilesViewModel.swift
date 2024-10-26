//
//  FilesViewModel.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/10/18.
//

// import Foundation
// import FirebaseFirestore
// import FirebaseStorage
//
// class FilesViewModel: NSObject {
//    
//    // MARK: - Properties
//    
//    var files: [FileItem] = [] {
//        didSet {
//            filesUpdated?()
//        }
//    }
//    
//    var selectedFiles: [FileItem] = []
//    var studentInfos: [Student] = [] {
//        didSet {
//            studentsUpdated?()
//        }
//    }
//    var selectedStudentIDs: Set<String> = []
//    
//    var fileDownloadProgress: [URL: Float] = [:]
//    var fileDownloadStatus: [URL: Bool] = [:]
//    
//    var userRole: UserRole
//    
//    // Closures to notify the ViewController
//    var filesUpdated: (() -> Void)?
//    var studentsUpdated: (() -> Void)?
//    var downloadProgressUpdated: ((URL, Float) -> Void)?
//    var fileDownloadCompleted: ((URL) -> Void)?
//    
//    // Firebase references
//    let storage = Storage.storage()
//    let firestore = Firestore.firestore()
//    let userID = UserSession.shared.currentUserID
//    
//    // URLSession for downloads
//    lazy var session: URLSession = {
//        let sessionConfig = URLSessionConfiguration.default
//        return URLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
//    }()
//    
//    // MARK: - Initialization
//    
//    override init() {
//        if let roleString = UserDefaults.standard.string(forKey: "userRole"),
//           let role = UserRole(rawValue: roleString) {
//            self.userRole = role
//        } else {
//            self.userRole = .teacher
//        }
//        super.init()
//    }
//    
//    // MARK: - Fetch Files
//    
//    func fetchUserFiles() {
//        guard let currentUserID = userID else {
//            print("Error: Current user ID is nil.")
//            self.files = []
//            return
//        }
//        
//        let collectionPath = "files"
//        let queryField = userRole == .teacher ? "ownerID" : "authorizedStudents"
//        
//        let query: Query
//        if userRole == .teacher {
//            query = firestore.collection(collectionPath).whereField(queryField, isEqualTo: currentUserID)
//        } else {
//            query = firestore.collection(collectionPath).whereField(queryField, arrayContains: currentUserID)
//        }
//        
//        query.addSnapshotListener { [weak self] (snapshot, error) in
//            if let error = error {
//                print("Error fetching user files: \(error.localizedDescription)")
//                self?.files = []
//                return
//            }
//            
//            guard let snapshot = snapshot else {
//                print("No snapshot received.")
//                self?.files = []
//                return
//            }
//            
//            self?.handleFetchedFiles(snapshot)
//        }
//    }
//    
//    private func handleFetchedFiles(_ snapshot: QuerySnapshot?) {
//        guard let documents = snapshot?.documents else {
//            print("No files found.")
//            self.files = []
//            return
//        }
//        
//        var updatedFiles: [FileItem] = []
//        self.fileDownloadStatus.removeAll()
//        
//        for document in documents {
//            guard let urlString = document.data()["downloadURL"] as? String,
//                  let fileName = document.data()["fileName"] as? String,
//                  let remoteURL = URL(string: urlString) else {
//                continue
//            }
//            
//            if let cachedURL = isFileCached(fileName: fileName) {
//                let storagePath = document.data()["storagePath"] as? String ?? "files/\(fileName)"
//                let fileItem = FileItem(localURL: cachedURL, remoteURL: remoteURL, downloadURL: urlString, fileName: fileName, storagePath: storagePath)
//                updatedFiles.append(fileItem)
//                self.fileDownloadStatus[remoteURL] = false
//            } else {
//                let storagePath = document.data()["storagePath"] as? String ?? "files/\(fileName)"
//                let fileItem = FileItem(localURL: nil, remoteURL: remoteURL, downloadURL: urlString, fileName: fileName, storagePath: storagePath)
//                updatedFiles.append(fileItem)
//                self.fileDownloadStatus[remoteURL] = true
//                
//                self.downloadFile(from: remoteURL, withName: fileName)
//            }
//        }
//        
//        self.files = updatedFiles
//    }
//    
//    // MARK: - Download File
//    
//    func downloadFile(from url: URL, withName fileName: String) {
//        let task = session.downloadTask(with: url)
//        task.resume()
//    }
//    
//    // MARK: - URLSessionDownloadDelegate methods
//    
//    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
//                    didWriteData bytesWritten: Int64,
//                    totalBytesWritten: Int64,
//                    totalBytesExpectedToWrite: Int64) {
//        guard let url = downloadTask.originalRequest?.url else { return }
//        
//        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
//        
//        DispatchQueue.main.async {
//            self.fileDownloadProgress[url] = progress
//            self.downloadProgressUpdated?(url, progress)
//        }
//    }
//    
//    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
//                    didFinishDownloadingTo location: URL) {
//        guard let url = downloadTask.originalRequest?.url else { return }
//        let fileName = url.lastPathComponent
//        let cacheDirectory = getCacheDirectory()
//        let localUrl = cacheDirectory.appendingPathComponent(fileName)
//        
//        do {
//            if FileManager.default.fileExists(atPath: localUrl.path) {
//                try FileManager.default.removeItem(at: localUrl)
//            }
//            try FileManager.default.moveItem(at: location, to: localUrl)
//            
//            if let index = self.files.firstIndex(where: { $0.remoteURL == url }) {
//                var fileItem = self.files[index]
//                fileItem.localURL = localUrl
//                self.files[index] = fileItem
//                
//                self.fileDownloadStatus[url] = false
//                self.fileDownloadProgress.removeValue(forKey: url)
//                
//                DispatchQueue.main.async {
//                    self.fileDownloadCompleted?(url)
//                }
//            }
//        } catch {
//            print("Error moving file: \(error.localizedDescription)")
//        }
//    }
//    
//    // MARK: - Upload File
//    
//    func uploadFileToFirebase(_ fileURL: URL, fileName: String, completion: @escaping (Result<String, Error>) -> Void) {
//        guard let currentUserID = userID else {
//            print("Error: Current user ID is nil.")
//            completion(.failure(NSError(domain: "UserSession", code: -1, userInfo: [NSLocalizedDescriptionKey: "Current user ID is nil."])))
//            return
//        }
//        
//        guard fileURL.startAccessingSecurityScopedResource() else {
//            print("Cannot access security scoped resource")
//            completion(.failure(NSError(domain: "FileAccess", code: -1, userInfo: [NSLocalizedDescriptionKey: "Cannot access security scoped resource"])))
//            return
//        }
//        defer {
//            fileURL.stopAccessingSecurityScopedResource()
//        }
//        
//        let cacheDirectory = getCacheDirectory()
//        let cachedFileURL = cacheDirectory.appendingPathComponent(fileName)
//        do {
//            if FileManager.default.fileExists(atPath: cachedFileURL.path) {
//                try FileManager.default.removeItem(at: cachedFileURL)
//            }
//            try FileManager.default.copyItem(at: fileURL, to: cachedFileURL)
//            print("Successfully copied file to cache directory: \(cachedFileURL.path)")
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
//            let uploadTask = storageRef.putData(fileData, metadata: metadata) { metadata, error in
//                if let error = error {
//                    print("Upload failed with error: \(error.localizedDescription)")
//                    completion(.failure(error))
//                    return
//                }
//                
//                storageRef.downloadURL { url, error in
//                    if let error = error {
//                        print("Download URL fetch failed with error: \(error.localizedDescription)")
//                        completion(.failure(error))
//                    } else if let url = url {
//                        print("Upload successful. Download URL: \(url.absoluteString)")
//                        
//                        self.saveFileMetadataToFirestore(downloadURL: url.absoluteString, storagePath: storagePath, fileName: fileName)
//                        
//                        let newFileItem = FileItem(localURL: cachedFileURL, remoteURL: url, downloadURL: url.absoluteString, fileName: fileName, storagePath: storagePath)
//                        
//                        DispatchQueue.main.async {
//                            self.files.append(newFileItem)
//                        }
//                        
//                        completion(.success(url.absoluteString))
//                    }
//                }
//            }
//            
//            uploadTask.observe(.progress) { snapshot in
//                if let progress = snapshot.progress {
//                    let percentComplete = 100.0 * Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
//                    DispatchQueue.main.async {
//                        // Update progress if needed
//                    }
//                }
//            }
//            
//            uploadTask.observe(.failure) { snapshot in
//                if let error = snapshot.error {
//                    print("Upload failed during progress update: \(error.localizedDescription)")
//                    completion(.failure(error))
//                }
//            }
//            
//        } catch {
//            print("Error reading file data: \(error.localizedDescription)")
//            completion(.failure(error))
//        }
//    }
//    
//    func saveFileMetadataToFirestore(downloadURL: String, storagePath: String, fileName: String) {
//        let currentUserID = userID ?? "unknown_user"
//        let fileData: [String: Any] = [
//            "fileName": fileName,
//            "downloadURL": downloadURL,
//            "storagePath": storagePath,
//            "createdAt": Timestamp(),
//            "ownerID": currentUserID,
//            "authorizedStudents": []
//        ]
//        
//        firestore.collection("files").addDocument(data: fileData) { error in
//            if let error = error {
//                print("Error saving file metadata: \(error.localizedDescription)")
//            } else {
//                print("File metadata saved successfully.")
//            }
//        }
//    }
//    
//    // MARK: - Delete File
//    
//    func deleteFile(fileItem: FileItem, completion: @escaping (Result<Void, Error>) -> Void) {
//        guard let storagePath = fileItem.storagePath, !storagePath.isEmpty else {
//            print("Error: storagePath is nil or empty.")
//            completion(.failure(NSError(domain: "DeleteFile", code: -1, userInfo: [NSLocalizedDescriptionKey: "Storage path is invalid."])))
//            return
//        }
//        
//        let storageRef = storage.reference().child(storagePath)
//        
//        storageRef.delete { [weak self] error in
//            if let error = error {
//                print("Error deleting file from Storage: \(error.localizedDescription)")
//                completion(.failure(error))
//                return
//            }
//            
//            self?.firestore.collection("files")
//                .whereField("storagePath", isEqualTo: storagePath)
//                .getDocuments { snapshot, error in
//                    if let error = error {
//                        print("Error deleting file metadata from Firestore: \(error.localizedDescription)")
//                        completion(.failure(error))
//                        return
//                    }
//                    
//                    guard let document = snapshot?.documents.first else {
//                        print("File not found in Firestore.")
//                        completion(.failure(NSError(domain: "DeleteFile", code: -1, userInfo: [NSLocalizedDescriptionKey: "File not found in Firestore."])))
//                        return
//                    }
//                    
//                    document.reference.delete { error in
//                        if let error = error {
//                            print("Error deleting file metadata from Firestore: \(error.localizedDescription)")
//                            completion(.failure(error))
//                        } else {
//                            print("Successfully deleted metadata for file: \(fileItem.fileName)")
//                            
//                            do {
//                                if let localURL = fileItem.localURL, FileManager.default.fileExists(atPath: localURL.path) {
//                                    try FileManager.default.removeItem(at: localURL)
//                                    print("Local file deleted successfully.")
//                                }
//                            } catch {
//                                print("Error deleting local file: \(error.localizedDescription)")
//                            }
//                            
//                            if let index = self?.files.firstIndex(where: { $0.fileName == fileItem.fileName && $0.remoteURL == fileItem.remoteURL }) {
//                                self?.files.remove(at: index)
//                            }
//                            
//                            completion(.success(()))
//                        }
//                    }
//                }
//        }
//    }
//    
//    // MARK: - Helper Methods
//    
//    func getCacheDirectory() -> URL {
//        let fileManager = FileManager.default
//        let cacheDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("FileCache")
//        
//        if !fileManager.fileExists(atPath: cacheDirectory.path) {
//            do {
//                try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true, attributes: nil)
//            } catch {
//                print("Error creating cache directory: \(error.localizedDescription)")
//            }
//        }
//        
//        return cacheDirectory
//    }
//    
//    func isFileCached(fileName: String) -> URL? {
//        let filePath = getCacheDirectory().appendingPathComponent(fileName)
//        if FileManager.default.fileExists(atPath: filePath.path) {
//            return filePath
//        }
//        return nil
//    }
//    
//    // Add other helper methods as needed
// }
//
// extension FilesViewModel: URLSessionDownloadDelegate {
//    // URLSessionDownloadDelegate methods are implemented in the class above
// }
