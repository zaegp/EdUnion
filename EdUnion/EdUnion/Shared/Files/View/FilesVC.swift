//
//  FilesVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/26.
//

import UIKit
import FirebaseStorage
import FirebaseFirestore
import QuickLook

class FilesVC: UIViewController, QLPreviewControllerDataSource {
    var collectionView: UICollectionView!
    var studentTableView: UITableView!
    var sendButton: UIButton!
    var previewItem: NSURL?
    var fileDownloadProgress: [URL: Float] = [:]
    var activityIndicator: UIActivityIndicatorView!
    
    var selectedFiles: [FileItem] = []
    var files: [FileItem] = []
    var studentInfos: [Student] = []
    var selectedStudentIDs: Set<String> = []
    
    let storage = Storage.storage()
    let firestore = Firestore.firestore()
    let userID = UserSession.shared.currentUserID
    
    var documentInteractionController: UIDocumentInteractionController?
    var currentUploadTask: StorageUploadTask?
    
    private var userRole: UserRole = UserRole(rawValue: UserDefaults.standard.string(forKey: "userRole") ?? "teacher") ?? .teacher

    var fileURLs: [URL: String] = [:]
    var fileDownloadStatus: [URL: Bool] = [:]
    
    var collectionViewBottomConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .myBackground
        
        setupCollectionView()
        
        if userRole == .teacher {
            setupSendButton()
            setupStudentTableView()
            setupLongPressGesture()
            setupMenu()
            setupActivityIndicator()
        }
        
        fetchUserFiles()
        enableSwipeToGoBack()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let tabBarController = self.tabBarController as? TabBarController {
            tabBarController.setCustomTabBarHidden(true, animated: true)
        }
    }
    
    private func setupActivityIndicator() {
        activityIndicator = UIActivityIndicatorView(style: .large)
                activityIndicator.center = self.view.center
                activityIndicator.hidesWhenStopped = true // 在停止時隱藏
                self.view.addSubview(activityIndicator)
    }
    
    func showActivityIndicator() {
            DispatchQueue.main.async {
                self.activityIndicator.startAnimating()
            }
        }
        
        // 隱藏活動指示器
        func hideActivityIndicator() {
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
            }
        }
    
    private func setupSendButton() {
        sendButton = UIButton(type: .system)
        sendButton.isHidden = true
        sendButton.setTitle("傳送", for: .normal)
        sendButton.backgroundColor = .mainOrange
        sendButton.setTitleColor(.white, for: .normal)
        sendButton.layer.cornerRadius = 8
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(sendFilesToSelectedStudents), for: .touchUpInside)
        
        view.addSubview(sendButton)
        
        NSLayoutConstraint.activate([
            sendButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            sendButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            sendButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            sendButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupMenu() {
        let menuButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), style: .plain, target: nil, action: nil)
        menuButton.tintColor = .mainOrange
        navigationItem.rightBarButtonItem = menuButton
        
        let menu = UIMenu(title: "", children: [
            UIAction(title: "上傳檔案", image: UIImage(systemName: "doc.badge.plus")) { [weak self] _ in
                self?.uploadFiles()
            },
            UIAction(title: "選取多個文件分享", image: UIImage(systemName: "square.and.arrow.up")) { [weak self] _ in
                self?.selectMultipleFilesForSharing()
            }
        ])
        
        menuButton.menu = menu
        menuButton.primaryAction = nil
    }
    
    private func setupStudentTableView() {
        studentTableView = UITableView()
        studentTableView.backgroundColor = .myBackground
        studentTableView.delegate = self
        studentTableView.dataSource = self
        studentTableView.register(StudentTableViewCell.self, forCellReuseIdentifier: "StudentCell")
        studentTableView.translatesAutoresizingMaskIntoConstraints = false
        studentTableView.isHidden = true
        
        view.addSubview(studentTableView)
        
        NSLayoutConstraint.activate([
            studentTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            studentTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            studentTableView.topAnchor.constraint(equalTo: collectionView.bottomAnchor),
            studentTableView.bottomAnchor.constraint(equalTo: sendButton.topAnchor)
        ])
        
        fetchStudentsNotes(forTeacherID: userID ?? "") { [weak self] notes in
            for (studentID, _) in notes {
                self?.fetchUser(from: "students", userID: studentID, as: Student.self)
            }
        }
    }
    
    func setEmptyMessage(_ message: String) {
        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.textColor = .myGray
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        messageLabel.sizeToFit()
        
        studentTableView.backgroundView = messageLabel
        studentTableView.separatorStyle = .none
    }
    
    func restoreTableView() {
        studentTableView.backgroundView = nil
        studentTableView.separatorStyle = .singleLine
    }
    
    @objc func selectMultipleFilesForSharing() {
        collectionView.allowsMultipleSelection = true
        sendButton.isHidden = false
        updateSendButtonState()
        studentTableView.isHidden = false
    }
    
    func fetchStudentsNotes(forTeacherID teacherID: String, completion: @escaping ([String: String]) -> Void) {
        firestore.collection("teachers").document(teacherID).getDocument { (snapshot, error) in
            if let error = error {
                print("Error fetching studentsNotes: \(error.localizedDescription)")
                completion([:])
                return
            }
            
            guard let data = snapshot?.data(), let studentsNotes = data["studentsNotes"] as? [String: String] else {
                print("No studentsNotes found for teacher \(teacherID)")
                completion([:])
                return
            }
            
            completion(studentsNotes)
        }
    }
    
    func fetchUser<T: UserProtocol & Decodable>(from collection: String, userID: String, as type: T.Type) {
        UserFirebaseService.shared.fetchUser(from: collection, by: userID, as: type) { [weak self] result in
            switch result {
            case .success(let user):
                if let student = user as? Student {
                    self?.studentInfos.append(student)
                }
                DispatchQueue.main.async {
                    self?.studentTableView.reloadData()
                }
            case .failure(let error):
                print("Error fetching user: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func sendFilesToSelectedStudents() {
        guard !selectedFiles.isEmpty, !selectedStudentIDs.isEmpty else {
            print("沒有選擇任何文件或學生")
            return
        }
        
        startSendAnimation()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            for studentID in self.selectedStudentIDs {
                for fileItem in self.selectedFiles {
                    print("發送文件 \(fileItem.fileName) 給學生 \(studentID)")
                    
                    let fileName = fileItem.fileName
                    
                    self.firestore.collection("files")
                        .whereField("fileName", isEqualTo: fileName)
                        .getDocuments { (snapshot, error) in
                            if let error = error {
                                print("Error finding file in Firestore: \(error.localizedDescription)")
                                return
                            }
                            
                            guard let document = snapshot?.documents.first else {
                                print("File not found in Firestore.")
                                return
                            }
                            
                            document.reference.updateData([
                                "authorizedStudents": FieldValue.arrayUnion([studentID])
                            ]) { error in
                                if let error = error {
                                    print("Error adding student to authorized list: \(error)")
                                } else {
                                    print("Student \(studentID) added to authorized list for file \(fileName) successfully.")
                                }
                            }
                        }
                }
            }
            
            self.selectedFiles.removeAll()
            self.selectedStudentIDs.removeAll()
            self.studentTableView.reloadData()
            self.studentTableView.isHidden = true
            self.sendButton.isHidden = true
            self.collectionView.allowsMultipleSelection = false
            self.collectionView.reloadData()
            
            self.endSendAnimation()
        }
    }

    func startSendAnimation() {
        // 創建飛機圖標
        let planeImageView = UIImageView(image: UIImage(systemName: "paperplane.fill"))
        planeImageView.tintColor = .mainOrange
        planeImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(planeImageView)
        
        // 設置飛機圖標的位置
        NSLayoutConstraint.activate([
            planeImageView.centerXAnchor.constraint(equalTo: sendButton.centerXAnchor),
            planeImageView.centerYAnchor.constraint(equalTo: sendButton.centerYAnchor),
            planeImageView.widthAnchor.constraint(equalToConstant: 30),
            planeImageView.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        // 飛機飛走的動畫
        UIView.animate(withDuration: 1.0, animations: {
            planeImageView.transform = CGAffineTransform(translationX: self.view.frame.width, y: -self.view.frame.height / 2)
            planeImageView.alpha = 0
        }, completion: { _ in
            planeImageView.removeFromSuperview()
            
            // 顯示勾選圖標動畫
            self.showCheckmarkAnimation()
        })
    }

    func showCheckmarkAnimation() {
        // 創建勾選圖標
        let checkmarkImageView = UIImageView(image: UIImage(systemName: "checkmark"))
        checkmarkImageView.tintColor = .mainOrange
        
        checkmarkImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(checkmarkImageView)
        
        // 設置勾選圖標的位置在螢幕中心
        NSLayoutConstraint.activate([
            checkmarkImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            checkmarkImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 100),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 100)
        ])
        
        // 動畫效果：從小到大出現
        checkmarkImageView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        checkmarkImageView.alpha = 0
        UIView.animate(withDuration: 0.5, animations: {
            checkmarkImageView.transform = CGAffineTransform.identity
            checkmarkImageView.alpha = 1
        }, completion: { _ in
            // 延遲 1 秒後淡出並移除
            UIView.animate(withDuration: 0.5, delay: 1.0, options: [], animations: {
                checkmarkImageView.alpha = 0
            }, completion: { _ in
                checkmarkImageView.removeFromSuperview()
            })
        })
    }

    func endSendAnimation() {
        print("文件傳送完成")
    }
    
    func updateSendButtonState() {
        let canSend = !selectedFiles.isEmpty && !selectedStudentIDs.isEmpty
        sendButton.isEnabled = canSend
        sendButton.backgroundColor = canSend ? .mainOrange : .gray // 根據狀態改變背景色
    }
    
    private func previewFile(at url: URL) {
           if FileManager.default.fileExists(atPath: url.path) {
               previewItem = url as NSURL
               let previewController = QLPreviewController()
               previewController.dataSource = self
               present(previewController, animated: true, completion: nil)
           } else {
               print("File does not exist at path: \(url.path)")
               showAlert(title: "無法預覽", message: "文件不存在或已被刪除。")
           }
       }
       
       // QLPreviewControllerDataSource 方法
       func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
           return previewItem == nil ? 0 : 1
       }
       
       func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
           return previewItem!
       }
    
    func fetchUserFiles() {
        guard let currentUserID = UserSession.shared.currentUserID else {
            print("Error: Current user ID is nil.")
            setCustomEmptyStateView() // 顯示自定義的 empty state
            return
        }
        
        let cachedFiles = getCachedFiles()
        if !cachedFiles.isEmpty {
            self.files = cachedFiles
            DispatchQueue.main.async {
                self.collectionView.reloadData()
                self.restoreCollectionView() // 恢復正常背景
            }
            // 如果有緩存的文件，暫時不設置監聽器
            return
        } else {
            setCustomEmptyStateView()
        }
        
        setupFirestoreListener(for: currentUserID)
    }
    
    func setupFirestoreListener(for currentUserID: String) {
        let collectionPath = "files"
        let queryField = userRole == .teacher ? "ownerID" : "authorizedStudents"

        let query = userRole == .teacher ?
            firestore.collection(collectionPath).whereField(queryField, isEqualTo: currentUserID) :
            firestore.collection(collectionPath).whereField(queryField, arrayContains: currentUserID)

        query.addSnapshotListener { [weak self] (snapshot, error) in
            if let error = error {
                print("Error fetching user files: \(error.localizedDescription)")
                self?.setCustomEmptyStateView() // 顯示自定義的 empty state
                return
            }

            guard let snapshot = snapshot else {
                print("No snapshot received.")
                self?.files.removeAll()
                self?.collectionView.reloadData()
                self?.setCustomEmptyStateView() // 顯示自定義的 empty state
                return
            }

            // 處理即時變動的文件
            self?.handleFetchedFiles(snapshot)
        }
    }
    
    func getCachedFiles() -> [FileItem] {
        let fileManager = FileManager.default
        let cacheDirectory = getCacheDirectory()

        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            var cachedFiles: [FileItem] = []

            for fileURL in fileURLs {
                let fileName = fileURL.lastPathComponent
                let fileItem = FileItem(localURL: fileURL, remoteURL: fileURL, downloadURL: "", fileName: fileName, storagePath: "files/\(fileName)")
                cachedFiles.append(fileItem)
            }
            return cachedFiles
        } catch {
            print("Error fetching cached files: \(error.localizedDescription)")
            return []
        }
    }
    
    private func handleFetchedFiles(_ snapshot: QuerySnapshot?) {
        guard let documents = snapshot?.documents else {
            print("No files found.")
            self.files.removeAll()
            self.collectionView.reloadData()
            setCustomEmptyStateView() // 設置自定義的 empty state
            return
        }

        // 創建一個臨時的文件列表
        var updatedFiles: [FileItem] = []
        self.fileDownloadStatus.removeAll()
        self.fileURLs.removeAll()

        for document in documents {
            guard let urlString = document.data()["downloadURL"] as? String,
                  let fileName = document.data()["fileName"] as? String,
                  let remoteURL = URL(string: urlString) else {
                continue
            }

            // 檢查本地緩存
            if let cachedURL = isFileCached(fileName: fileName) {
                let storagePath = document.data()["storagePath"] as? String ?? "files/\(fileName)"
                let fileItem = FileItem(localURL: cachedURL, remoteURL: remoteURL, downloadURL: urlString, fileName: fileName, storagePath: storagePath)
                updatedFiles.append(fileItem)
                self.fileDownloadStatus[remoteURL] = false
            } else {
                let storagePath = document.data()["storagePath"] as? String ?? "files/\(fileName)"
                let fileItem = FileItem(localURL: nil, remoteURL: remoteURL, downloadURL: urlString, fileName: fileName, storagePath: storagePath)
                updatedFiles.append(fileItem)
                self.fileDownloadStatus[remoteURL] = true

                // 刷新 collectionView 以顯示活動指示器
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }

                self.downloadFile(from: remoteURL, withName: fileName)
            }
        }

        // 更新 self.files
        self.files = updatedFiles

        DispatchQueue.main.async {
            self.collectionView.reloadData()
            if self.files.isEmpty {
                self.setCustomEmptyStateView() // 顯示自定義的 empty state 視圖
            } else {
                self.restoreCollectionView()  // 恢復正常背景
            }
        }
    }
    
//    func downloadFile(from url: URL, withName fileName: String) {
//        let task = URLSession.shared.downloadTask(with: url) { [weak self] (tempLocalUrl, response, error) in
//            if let error = error {
//                print("Error downloading file: \(error.localizedDescription)")
//                return
//            }
//
//            guard let tempLocalUrl = tempLocalUrl else {
//                print("Error: Temporary local URL is nil.")
//                return
//            }
//
//            let cacheDirectory = self?.getCacheDirectory()
//            let localUrl = cacheDirectory?.appendingPathComponent(fileName)
//
//            do {
//                if let localUrl = localUrl {
//                    if FileManager.default.fileExists(atPath: localUrl.path) {
//                        try FileManager.default.removeItem(at: localUrl)
//                    }
//                    try FileManager.default.moveItem(at: tempLocalUrl, to: localUrl)
//
//                    DispatchQueue.main.async {
//                        // 更新 files 列表以指向本地緩存文件
//                        if let index = self?.files.firstIndex(where: { $0.remoteURL == url }) {
//                            let updatedFileItem = FileItem(localURL: localUrl, remoteURL: url, downloadURL: self?.files[index].downloadURL ?? "", fileName: fileName)
//                            self?.files[index] = updatedFileItem
//                        }
//                        self?.fileDownloadStatus[localUrl] = false
//                        self?.collectionView.reloadData()
//
//                        // Update empty state
//                        if let self = self, self.files.isEmpty {
//
//                        } else {
//                            self?.restoreCollectionView()
//                        }
//                    }
//                }
//            } catch {
//                print("Error moving file: \(error.localizedDescription)")
//            }
//        }
//        task.resume()
//    }
    
    func setupCollectionView() {
        
        let layout = UICollectionViewFlowLayout()
        
        // 設置每行顯示的單元格數量
        let numberOfItemsPerRow: CGFloat = 3
        // 設置單元格之間的間距
        let spacing: CGFloat = 10
        
        // 計算每個單元格的寬度
        let totalSpacing = (2 * spacing) + ((numberOfItemsPerRow - 1) * spacing) // 頁面左右和單元格之間的總間距
        let itemWidth = (view.bounds.width - totalSpacing) / numberOfItemsPerRow
        
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth + 20) // 調整高度以容納標籤
        layout.sectionInset = UIEdgeInsets(top: spacing, left: spacing, bottom: spacing, right: spacing)
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.allowsMultipleSelection = false
        collectionView.register(FileCell.self, forCellWithReuseIdentifier: "fileCell")
        collectionView.backgroundColor = .myBackground
        view.addSubview(collectionView)
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        collectionViewBottomConstraint = collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leftAnchor.constraint(equalTo: view.leftAnchor),
            collectionView.rightAnchor.constraint(equalTo: view.rightAnchor),
            collectionViewBottomConstraint
        ])
        
        updateCollectionViewConstraints()
    }
    
    func updateCollectionViewConstraints() {
        if userRole == .student {
            collectionViewBottomConstraint.constant = 0
        } else {
            collectionViewBottomConstraint.constant = -300
        }
    }
    
//    func uploadAllFiles() {
//        for fileItem in files {
//            guard let localURL = fileItem.localURL else {
//                print("File \(fileItem.fileName) 已經上傳，跳過。")
//                continue
//            }
//
//            uploadFileToFirebase(localURL, fileName: fileItem.fileName) { [weak self] result in
//                switch result {
//                case .success(let downloadURL):
//                    self?.saveFileMetadataToFirestore(downloadURL: downloadURL, fileName: fileItem.fileName)
//                case .failure(let error):
//                    print("File upload failed for \(fileItem.fileName): \(error.localizedDescription)")
//                }
//            }
//        }
//    }
    
    @objc func uploadFiles() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.item])
        documentPicker.delegate = self
        present(documentPicker, animated: true, completion: nil)
    }
    
    // MARK: - 文件上傳到 Firebase
    func generateUniqueFileName(originalName: String) -> String {
        let uuid = UUID().uuidString
        return "\(uuid)_\(originalName)"
    }
    
    func uploadFileToFirebase(_ fileURL: URL, fileName: String, retryCount: Int = 3, completion: @escaping (Result<String, Error>) -> Void) {
        guard let currentUserID = UserSession.shared.currentUserID else {
            print("Error: Current user ID is nil.")
            completion(.failure(NSError(domain: "UserSession", code: -1, userInfo: [NSLocalizedDescriptionKey: "Current user ID is nil."])))
            return
        }
        
        // Step 1: Copy the file to the app's cache directory
        let cacheDirectory = getCacheDirectory()
        let cachedFileURL = cacheDirectory.appendingPathComponent(fileName)
        do {
            if FileManager.default.fileExists(atPath: cachedFileURL.path) {
                try FileManager.default.removeItem(at: cachedFileURL)
            }
            try FileManager.default.copyItem(at: fileURL, to: cachedFileURL)
        } catch {
            print("Error copying file to cache directory: \(error.localizedDescription)")
            completion(.failure(error))
            return
        }
        
        let storagePath = "files/\(fileName)"
        let storageRef = storage.reference().child(storagePath)
        
        do {
            let fileData = try Data(contentsOf: cachedFileURL)
            let metadata = StorageMetadata()
            metadata.contentType = "application/octet-stream"
            metadata.customMetadata = ["ownerId": currentUserID]
            
            print("Starting upload for file: \(fileName)")
            showActivityIndicator()
            
            DispatchQueue.main.async {
                // 显示上传进度指示器
//                self.showUploadProgress(for: fileName)
            }
            
            let uploadTask = storageRef.putData(fileData, metadata: metadata) { metadata, error in
                self.hideActivityIndicator()
                if let error = error {
                    if retryCount > 0 {
                        print("Upload failed, retrying... (\(retryCount) retries left)")
                        self.uploadFileToFirebase(cachedFileURL, fileName: fileName, retryCount: retryCount - 1, completion: completion)
                    } else {
                        print("Upload failed with error: \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                    return
                }
                
                print("Upload completed, fetching download URL.")
                
                storageRef.downloadURL { url, error in
                    if let error = error {
                        if retryCount > 0 {
                            print("Download URL fetch failed, retrying... (\(retryCount) retries left)")
                            self.uploadFileToFirebase(cachedFileURL, fileName: fileName, retryCount: retryCount - 1, completion: completion)
                        } else {
                            print("Download URL fetch failed with error: \(error.localizedDescription)")
                            completion(.failure(error))
                        }
                    } else if let url = url {
                        print("Upload successful. Download URL: \(url.absoluteString)")
                        
                        // 保存文件元数据到 Firestore
                        self.saveFileMetadataToFirestore(downloadURL: url.absoluteString, storagePath: storagePath, fileName: fileName)
                        
                        // Step 2: 创建新的 FileItem 并添加到 files 数组
                        let newFileItem = FileItem(localURL: cachedFileURL, remoteURL: url, downloadURL: url.absoluteString, fileName: fileName, storagePath: storagePath)
                        DispatchQueue.main.async {
                            self.files.append(newFileItem)
                            self.collectionView.reloadData()
                            // 隐藏上传进度指示器
//                            self.hideUploadProgress(for: fileName)
                        }
                        
                        completion(.success(url.absoluteString))
                    }
                }
            }
            
            // 监控上传进度
            uploadTask.observe(.progress) { snapshot in
                if let progress = snapshot.progress {
                    let percentComplete = 100.0 * Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                    DispatchQueue.main.async {
                        // 更新上传进度指示器
//                        self.updateUploadProgress(for: fileName, progress: percentComplete)
                    }
                }
            }
            
            uploadTask.observe(.failure) { snapshot in
                self.hideActivityIndicator()
                if let error = snapshot.error {
                    print("Upload failed during progress update: \(error.localizedDescription)")
                    // 可选：在这里调用 completion(.failure(error)) 或实现其他错误处理
                }
            }
            
            self.currentUploadTask = uploadTask
        } catch {
            print("Error reading file data: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }
    
    //    @objc func uploadFiles() {
    //        print("Upload button clicked.")
    //        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.item])
    //        documentPicker.delegate = self
    //        present(documentPicker, animated: true, completion: nil)
    //
    //        print("Document picker presented.")
    //    }
    
    func saveFileMetadataToFirestore(downloadURL: String, storagePath: String, fileName: String) {
        let currentUserID = UserSession.shared.currentUserID ?? "unknown_user"
        let fileData: [String: Any] = [
            "fileName": fileName,
            "downloadURL": downloadURL,
            "storagePath": storagePath,
            "createdAt": Timestamp(),
            "ownerID": currentUserID,
            "authorizedStudents": []
        ]
        
        firestore.collection("files").addDocument(data: fileData) { error in
            if let error = error {
                print("Error saving file metadata: \(error.localizedDescription)")
            } else {
                print("File metadata saved successfully.")
            }
        }
    }
    
    func setupLongPressGesture() {
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        collectionView.addGestureRecognizer(longPressGesture)
    }
    
    @objc func handleLongPress(gesture: UILongPressGestureRecognizer) {
        let point = gesture.location(in: collectionView)
        if let indexPath = collectionView.indexPathForItem(at: point) {
            editFileName(at: indexPath)
        }
    }
    
    func updateFileName(at indexPath: IndexPath, newName: String) {
        var fileItem = files[indexPath.item]
        
        // 生成新的文件名
        let newFileName = newName
        
        // 更新本地文件名稱（如果有本地文件）
        if let localURL = fileItem.localURL {
            let newLocalURL = localURL.deletingLastPathComponent().appendingPathComponent(newFileName)
            
            do {
                // 重命名本地文件
                try FileManager.default.moveItem(at: localURL, to: newLocalURL)
                
                // 更新文件數據
                fileItem = FileItem(localURL: newLocalURL, remoteURL: fileItem.remoteURL, downloadURL: fileItem.downloadURL, fileName: newFileName)
                files[indexPath.item] = fileItem
            } catch {
                print("Error renaming local file: \(error.localizedDescription)")
                showAlert(title: "重命名失敗", message: "無法重命名本地文件。")
                return
            }
        }
        
        // 更新 Firestore 中的文件名稱
        updateFileMetadataInFirestore(for: fileItem, newFileName: newFileName)
        
        // 重新載入 CollectionView
        collectionView.reloadItems(at: [indexPath])
    }
    
    func updateFileMetadataInFirestore(for fileItem: FileItem, newFileName: String) {
        firestore.collection("files")
            .whereField("downloadURL", isEqualTo: fileItem.downloadURL)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error finding file in Firestore: \(error.localizedDescription)")
                    return
                }
                
                guard let document = snapshot?.documents.first else {
                    print("File not found in Firestore.")
                    return
                }
                
                // 更新 Firestore 中的文件名
                document.reference.updateData(["fileName": newFileName]) { error in
                    if let error = error {
                        print("Error updating file name in Firestore: \(error.localizedDescription)")
                    } else {
                        print("File name successfully updated in Firestore.")
                    }
                }
            }
    }
    
    // MARK: - Cache
    func getCacheDirectory() -> URL {
        let fileManager = FileManager.default
        let cacheDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("FileCache")
        
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            do {
                try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating cache directory: \(error.localizedDescription)")
            }
        }
        
        return cacheDirectory
    }
    
    func isFileCached(fileName: String) -> URL? {
        let filePath = getCacheDirectory().appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: filePath.path) {
            return filePath
        }
        return nil
    }
}

extension FilesVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return studentInfos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: StudentTableViewCell = tableView.dequeueReusableCell(withIdentifier: "StudentCell", for: indexPath)
        cell.backgroundColor = .myBackground
        let student = studentInfos[indexPath.row]
        cell.configure(with: student)
        
        if selectedStudentIDs.contains(student.id) {
            let checkmark = UIImageView(image: UIImage(systemName: "checkmark"))
            checkmark.tintColor = .mainOrange
            cell.accessoryView = checkmark
        } else {
            cell.accessoryView = nil
        }
        
        cell.selectionStyle = .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let student = studentInfos[indexPath.row]
        if selectedStudentIDs.contains(student.id) {
            selectedStudentIDs.remove(student.id)
        } else {
            selectedStudentIDs.insert(student.id)
        }
        
        tableView.reloadRows(at: [indexPath], with: .automatic)
        
        updateSendButtonState()
    }
}

extension FilesVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return files.count
    }
    
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "fileCell", for: indexPath) as! FileCell
//        let fileItem = files[indexPath.item]
//        cell.delegate = self
//
//        if let isDownloading = fileDownloadStatus[fileItem.remoteURL] {
//            cell.configure(with: fileItem, isDownloading: isDownloading, allowsMultipleSelection: collectionView.allowsMultipleSelection)
//        } else {
//            cell.configure(with: fileItem, isDownloading: false, allowsMultipleSelection: collectionView.allowsMultipleSelection)
//        }
//
//        if let progress = fileDownloadProgress[fileItem.remoteURL] {
//            cell.updateProgress(progress)
//        } else {
//            cell.updateProgress(0.0)
//        }
//
//        return cell
//    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: FileCell = collectionView.dequeueReusableCell(withReuseIdentifier: "fileCell", for: indexPath)
        let fileItem = files[indexPath.item]
        cell.delegate = self

        var isDownloading = false
        var progress: Float = 0.0

        if let isFileDownloading = fileDownloadStatus[fileItem.remoteURL] {
            isDownloading = isFileDownloading
        }

        if let downloadProgress = fileDownloadProgress[fileItem.remoteURL] {
            progress = downloadProgress
        }

        cell.configure(with: fileItem, isDownloading: isDownloading, allowsMultipleSelection: collectionView.allowsMultipleSelection)
        cell.updateProgress(progress)

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item < files.count {
            let fileItem = files[indexPath.item]
            
            if collectionView.allowsMultipleSelection {
                selectedFiles.append(fileItem)
                print("選擇文件：\(fileItem.fileName)")
                updateSendButtonState()
            } else {
                if let localURL = fileItem.localURL {
                    previewFile(at: localURL)
                } else {
                    showAlert(title: "無法預覽", message: "文件尚未下載完成。")
                }
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if indexPath.item < files.count {
            let deselectedFileItem = files[indexPath.item]
            
            if collectionView.allowsMultipleSelection {
                // 使用 FileItem 的 remoteURL 來查找對應的文件
                if let index = selectedFiles.firstIndex(where: { $0.remoteURL == deselectedFileItem.remoteURL }) {
                    selectedFiles.remove(at: index)
                }
                
                print("取消選擇文件：\(deselectedFileItem.fileName)")
                updateSendButtonState()
            }
        }
    }
}

extension FilesVC: FileCellDelegate {
    func fileCellDidRequestDelete(_ cell: FileCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        let fileItem = files[indexPath.item]
        
        let alert = UIAlertController(title: "刪除文件", message: "確定要刪除文件 \(fileItem.fileName) 嗎？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "刪除", style: .destructive, handler: { [weak self] _ in
            self?.deleteFile(at: indexPath)
        }))
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func fileCellDidRequestEditName(_ cell: FileCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        editFileName(at: indexPath)
    }

    func editFileName(at indexPath: IndexPath) {
        let fileItem = files[indexPath.item]
        let alertController = UIAlertController(title: "編輯文件名稱", message: "請輸入新的文件名稱", preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.text = fileItem.fileName
        }

        let confirmAction = UIAlertAction(title: "確定", style: .default) { [weak self] _ in
            if let newFileName = alertController.textFields?.first?.text, !newFileName.isEmpty {
                self?.updateFileName(at: indexPath, newName: newFileName)
            }
        }
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }
    
    func deleteFile(at indexPath: IndexPath) {
        guard indexPath.item < files.count else {
            print("Error: Index out of range.")
            return
        }
        
        let fileItem = files[indexPath.item]
        guard let storagePath = fileItem.storagePath, !storagePath.isEmpty else {
            print("Error: storagePath is nil or empty.")
            showAlert(title: "刪除失敗", message: "無法刪除文件，文件的存储路径无效。")
            return
        }
        
        print("Storage Path: \(storagePath)")
        print("Local URL: \(String(describing: fileItem.localURL))")
        print("Remote URL: \(fileItem.remoteURL)")
        
        let storageRef = storage.reference().child(storagePath)
        
        storageRef.delete { [weak self] error in
            if let error = error {
                print("Error deleting file from Storage: \(error.localizedDescription)")
                self?.showAlert(title: "刪除失敗", message: "無法刪除文件，請稍後再試。")
                return
            }
            
            self?.firestore.collection("files")
                .whereField("storagePath", isEqualTo: storagePath)
                .getDocuments { snapshot, error in
                    if let error = error {
                        print("Error deleting file metadata from Firestore: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let document = snapshot?.documents.first else {
                        print("File not found in Firestore.")
                        return
                    }
                    
                    document.reference.delete { error in
                        if let error = error {
                            print("Error deleting file metadata from Firestore: \(error.localizedDescription)")
                        } else {
                            print("Successfully deleted metadata for file: \(fileItem.fileName)")
                            
                            // 删除本地缓存的文件
                            do {
                                if let localURL = fileItem.localURL, FileManager.default.fileExists(atPath: localURL.path) {
                                    try FileManager.default.removeItem(at: localURL)
                                    print("Local file deleted successfully.")
                                }
                            } catch {
                                print("Error deleting local file: \(error.localizedDescription)")
                            }
                            
                            DispatchQueue.main.async { [weak self] in
                                guard let self = self else { return }
                                if let currentIndex = self.files.firstIndex(where: { $0.fileName == fileItem.fileName && $0.remoteURL == fileItem.remoteURL }) {
                                    self.files.remove(at: currentIndex)
                                    self.collectionView.deleteItems(at: [IndexPath(item: currentIndex, section: 0)])
                                    
                                    if self.files.isEmpty {
                                        self.setCustomEmptyStateView()
                                    }
                                } else {
                                    self.collectionView.reloadData()
                                }
                            }
                        }
                    }
                }
        }
    }
}

extension FilesVC: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedURL = urls.first else { return }
        let fileName = selectedURL.lastPathComponent
        
        // 在上傳前檢查是否已存在同名檔案
        checkIfFileExists(fileName: fileName) { [weak self] exists in
            if exists {
                // 如果檔案已存在，提示用戶
                DispatchQueue.main.async {
                    self?.showAlert(title: "檔案已存在", message: "已存在同名檔案，請選擇其他檔案或更改檔案名稱。")
                }
            } else {
                self?.uploadFileToFirebase(selectedURL, fileName: fileName) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let downloadURL):
                            self?.showAlert(title: "上傳成功", message: "檔案已成功上傳。")
                        case .failure(let error):
                            print("檔案上傳失敗: \(error.localizedDescription)")
                            self?.showAlert(title: "上傳失敗", message: "無法上傳檔案，請稍後再試。")
                        }
                    }
                }
            }
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("用戶取消了文件選擇。")
    }
    
    func checkIfFileExists(fileName: String, completion: @escaping (Bool) -> Void) {
        guard let currentUserID = UserSession.shared.currentUserID else {
            completion(false)
            return
        }
        
        firestore.collection("files")
            .whereField("fileName", isEqualTo: fileName)
            .whereField("ownerID", isEqualTo: currentUserID)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error checking if file exists: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                if let documents = snapshot?.documents, !documents.isEmpty {
                    // 檔案已存在
                    completion(true)
                } else {
                    // 檔案不存在
                    completion(false)
                }
            }
    }
}

// MARK: - Empty State
extension FilesVC {
    func setCustomEmptyStateView() {
        let emptyStateView = UIView(frame: collectionView.bounds)
        
        let imageView = UIImageView(image: UIImage(systemName: "doc.text"))
        imageView.tintColor = .myGray
        imageView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.addSubview(imageView)
        
        let messageLabel = UILabel()
        messageLabel.text = userRole == .student ? "還沒有老師分享教材給你喔" : "沒有文件，請點擊右上角上傳文件"
        messageLabel.textColor = .myGray
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.addSubview(messageLabel)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: emptyStateView.centerYAnchor, constant: -20),
            imageView.widthAnchor.constraint(equalToConstant: 80),
            imageView.heightAnchor.constraint(equalToConstant: 80),
            
            messageLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            messageLabel.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor, constant: -20)
        ])
        
        collectionView.backgroundView = emptyStateView
    }
    
    func restoreCollectionView() {
        collectionView.backgroundView = nil
    }
}

// MARK: - Alert Helper
extension FilesVC {
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

extension FilesVC: URLSessionDownloadDelegate {

    func downloadFile(from url: URL, withName fileName: String) {
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
        let task = session.downloadTask(with: url)
        task.resume()
    }

    // MARK: - URLSessionDownloadDelegate 方法

    // 下载进度更新
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        guard let url = downloadTask.originalRequest?.url else { return }

        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        DispatchQueue.main.async {
            self.updateDownloadProgress(for: url, progress: progress)
        }
    }

    // 下载完成
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        guard let url = downloadTask.originalRequest?.url else { return }
        let fileName = url.lastPathComponent
        let cacheDirectory = getCacheDirectory()
        let localUrl = cacheDirectory.appendingPathComponent(fileName)

        do {
            if FileManager.default.fileExists(atPath: localUrl.path) {
                try FileManager.default.removeItem(at: localUrl)
            }
            try FileManager.default.moveItem(at: location, to: localUrl)

            DispatchQueue.main.async {
                if let index = self.files.firstIndex(where: { $0.remoteURL == url }) {
                    let updatedFileItem = FileItem(localURL: localUrl,
                                                   remoteURL: url,
                                                   downloadURL: self.files[index].downloadURL,
                                                   fileName: self.files[index].fileName)
                    self.files[index] = updatedFileItem
                    self.fileDownloadStatus[url] = false

                    // 刪除進度記錄
                    self.fileDownloadProgress.removeValue(forKey: url)

                    self.collectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
                }
            }
        } catch {
            print("移動文件時出錯: \(error.localizedDescription)")
        }
    }

    // 更新下载进度
    func updateDownloadProgress(for url: URL, progress: Double) {
        if let index = files.firstIndex(where: { $0.remoteURL == url }) {
            let indexPath = IndexPath(item: index, section: 0)

            if let cell = collectionView.cellForItem(at: indexPath) as? FileCell {
                cell.updateProgress(Float(progress))
            }
        }
    }
}

//class FilesVC: UIViewController, QLPreviewControllerDataSource {
//    var collectionView: UICollectionView!
//    var studentTableView: UITableView!
//    var sendButton: UIButton!
//    var previewItem: NSURL?
//    var fileDownloadProgress: [URL: Float] = [:]
//    var activityIndicator: UIActivityIndicatorView!
//    
//    var selectedFiles: [FileItem] = []
//    var files: [FileItem] = []
//    var studentInfos: [Student] = []
//    var selectedStudentIDs: Set<String> = []
//    
//    let fileFirebaseService = FileFirebaseService.shared
//    let userID = UserSession.shared.unwrappedUserID
//    
//    var documentInteractionController: UIDocumentInteractionController?
////    var currentUploadTask: StorageUploadTask?
//    
//    private var userRole: UserRole = UserRole(rawValue: UserDefaults.standard.string(forKey: "userRole") ?? "teacher") ?? .teacher
//
//    var fileURLs: [URL: String] = [:]
//    var fileDownloadStatus: [URL: Bool] = [:]
//    
//    var collectionViewBottomConstraint: NSLayoutConstraint!
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        view.backgroundColor = .myBackground
//        
//        setupCollectionView()
//        
//        if userRole == .teacher {
//            setupSendButton()
//            setupStudentTableView()
//            setupLongPressGesture()
//            setupMenu()
//            setupActivityIndicator()
//        }
//        
//        fetchUserFiles()
//        enableSwipeToGoBack()
//    }
//    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        
//        if let tabBarController = self.tabBarController as? TabBarController {
//            tabBarController.setCustomTabBarHidden(true, animated: true)
//        }
//    }
//    
//    private func setupActivityIndicator() {
//        activityIndicator = UIActivityIndicatorView(style: .large)
//                activityIndicator.center = self.view.center
//                activityIndicator.hidesWhenStopped = true
//                self.view.addSubview(activityIndicator)
//    }
//    
//    func showActivityIndicator() {
//            DispatchQueue.main.async {
//                self.activityIndicator.startAnimating()
//            }
//        }
//        
//        func hideActivityIndicator() {
//            DispatchQueue.main.async {
//                self.activityIndicator.stopAnimating()
//            }
//        }
//    
//    private func setupSendButton() {
//        sendButton = UIButton(type: .system)
//        sendButton.isHidden = true
//        sendButton.setTitle("傳送", for: .normal)
//        sendButton.backgroundColor = .mainOrange
//        sendButton.setTitleColor(.white, for: .normal)
//        sendButton.layer.cornerRadius = 8
//        sendButton.translatesAutoresizingMaskIntoConstraints = false
//        sendButton.addTarget(self, action: #selector(sendFilesToSelectedStudents), for: .touchUpInside)
//        
//        view.addSubview(sendButton)
//        
//        NSLayoutConstraint.activate([
//            sendButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
//            sendButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
//            sendButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
//            sendButton.heightAnchor.constraint(equalToConstant: 50)
//        ])
//    }
//    
//    private func setupMenu() {
//        let menuButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), style: .plain, target: nil, action: nil)
//        menuButton.tintColor = .mainOrange
//        navigationItem.rightBarButtonItem = menuButton
//        
//        let menu = UIMenu(title: "", children: [
//            UIAction(title: "上傳檔案", image: UIImage(systemName: "doc.badge.plus")) { [weak self] _ in
//                self?.uploadFiles()
//            },
//            UIAction(title: "選取多個文件分享", image: UIImage(systemName: "square.and.arrow.up")) { [weak self] _ in
//                self?.selectMultipleFilesForSharing()
//            }
//        ])
//        
//        menuButton.menu = menu
//        menuButton.primaryAction = nil
//    }
//    
//    private func setupStudentTableView() {
//        studentTableView = UITableView()
//        studentTableView.backgroundColor = .myBackground
//        studentTableView.delegate = self
//        studentTableView.dataSource = self
//        studentTableView.register(StudentTableViewCell.self, forCellReuseIdentifier: "StudentCell")
//        studentTableView.translatesAutoresizingMaskIntoConstraints = false
//        studentTableView.isHidden = true
//        
//        view.addSubview(studentTableView)
//        
//        NSLayoutConstraint.activate([
//            studentTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            studentTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            studentTableView.topAnchor.constraint(equalTo: collectionView.bottomAnchor),
//            studentTableView.bottomAnchor.constraint(equalTo: sendButton.topAnchor)
//        ])
//        fileFirebaseService.fetchStudentsNotes(forTeacherID: userID) { [weak self] notes in
//            for (studentID, _) in notes {
//                self?.fetchUser(from: "students", userID: studentID, as: Student.self)
//            }
//        }
//    }
//    
//    func setEmptyMessage(_ message: String) {
//        let messageLabel = UILabel()
//        messageLabel.text = message
//        messageLabel.textColor = .myGray
//        messageLabel.numberOfLines = 0
//        messageLabel.textAlignment = .center
//        messageLabel.font = UIFont.systemFont(ofSize: 20, weight: .medium)
//        messageLabel.sizeToFit()
//        
//        studentTableView.backgroundView = messageLabel
//        studentTableView.separatorStyle = .none
//    }
//    
//    func restoreTableView() {
//        studentTableView.backgroundView = nil
//        studentTableView.separatorStyle = .singleLine
//    }
//    
//    @objc func selectMultipleFilesForSharing() {
//        collectionView.allowsMultipleSelection = true
//        sendButton.isHidden = false
//        updateSendButtonState()
//        studentTableView.isHidden = false
//    }
//    
//    
//    
//    func fetchUser<T: UserProtocol & Decodable>(from collection: String, userID: String, as type: T.Type) {
//        UserFirebaseService.shared.fetchUser(from: collection, by: userID, as: type) { [weak self] result in
//            switch result {
//            case .success(let user):
//                if let student = user as? Student {
//                    self?.studentInfos.append(student)
//                }
//                DispatchQueue.main.async {
//                    self?.studentTableView.reloadData()
//                }
//            case .failure(let error):
//                print("Error fetching user: \(error.localizedDescription)")
//            }
//        }
//    }
//    
//    @objc func sendFilesToSelectedStudents() {
//        guard !selectedFiles.isEmpty, !selectedStudentIDs.isEmpty else {
//            showAlert(title: "操作無效", message: "請選擇至少一個文件和一個學生。")
//            return
//        }
//        
//        startSendAnimation()
//        
//        let fileNames = selectedFiles.map { $0.fileName }
//        let studentIDs = Array(selectedStudentIDs)
//        
//        fileFirebaseService.authorizeStudents(for: fileNames, studentIDs: studentIDs) { [weak self] result in
//            DispatchQueue.main.async {
//                self?.endSendAnimation()
//            }
//            switch result {
//            case .success:
//                print("文件成功發送給選定的學生。")
//                DispatchQueue.main.async {
//                    self?.selectedFiles.removeAll()
//                    self?.selectedStudentIDs.removeAll()
//                    self?.studentTableView.reloadData()
//                    self?.studentTableView.isHidden = true
//                    self?.sendButton.isHidden = true
//                    self?.collectionView.allowsMultipleSelection = false
//                    self?.collectionView.reloadData()
//                    self?.showAlert(title: "成功", message: "文件已成功發送給選定的學生。")
//                }
//            case .failure(let error):
//                print("發送文件時出錯: \(error.localizedDescription)")
//                DispatchQueue.main.async {
//                    self?.showAlert(title: "錯誤", message: "無法發送文件。請稍後再試。")
//                }
//            }
//        }
//    }
//
//    func startSendAnimation() {
//        let planeImageView = UIImageView(image: UIImage(systemName: "paperplane.fill"))
//        planeImageView.tintColor = .mainOrange
//        planeImageView.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(planeImageView)
//        
//        NSLayoutConstraint.activate([
//            planeImageView.centerXAnchor.constraint(equalTo: sendButton.centerXAnchor),
//            planeImageView.centerYAnchor.constraint(equalTo: sendButton.centerYAnchor),
//            planeImageView.widthAnchor.constraint(equalToConstant: 30),
//            planeImageView.heightAnchor.constraint(equalToConstant: 30)
//        ])
//        
//        UIView.animate(withDuration: 1.0, animations: {
//            planeImageView.transform = CGAffineTransform(translationX: self.view.frame.width, y: -self.view.frame.height / 2)
//            planeImageView.alpha = 0
//        }, completion: { _ in
//            planeImageView.removeFromSuperview()
//            
//            self.showCheckmarkAnimation()
//        })
//    }
//
//    func showCheckmarkAnimation() {
//        let checkmarkImageView = UIImageView(image: UIImage(systemName: "checkmark"))
//        checkmarkImageView.tintColor = .mainOrange
//        
//        checkmarkImageView.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(checkmarkImageView)
//        
//        NSLayoutConstraint.activate([
//            checkmarkImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            checkmarkImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
//            checkmarkImageView.widthAnchor.constraint(equalToConstant: 100),
//            checkmarkImageView.heightAnchor.constraint(equalToConstant: 100)
//        ])
//        
//        checkmarkImageView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
//        checkmarkImageView.alpha = 0
//        UIView.animate(withDuration: 0.5, animations: {
//            checkmarkImageView.transform = CGAffineTransform.identity
//            checkmarkImageView.alpha = 1
//        }, completion: { _ in
//            UIView.animate(withDuration: 0.5, delay: 1.0, options: [], animations: {
//                checkmarkImageView.alpha = 0
//            }, completion: { _ in
//                checkmarkImageView.removeFromSuperview()
//            })
//        })
//    }
//
//    func endSendAnimation() {
//        print("文件傳送完成")
//    }
//    
//    func updateSendButtonState() {
//        let canSend = !selectedFiles.isEmpty && !selectedStudentIDs.isEmpty
//        sendButton.isEnabled = canSend
//        sendButton.backgroundColor = canSend ? .mainOrange : .gray
//    }
//    
//    private func previewFile(at url: URL) {
//           if FileManager.default.fileExists(atPath: url.path) {
//               previewItem = url as NSURL
//               let previewController = QLPreviewController()
//               previewController.dataSource = self
//               present(previewController, animated: true, completion: nil)
//           } else {
//               print("File does not exist at path: \(url.path)")
//               showAlert(title: "無法預覽", message: "文件不存在或已被刪除。")
//           }
//       }
//       
//       func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
//           return previewItem == nil ? 0 : 1
//       }
//       
//       func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
//           return previewItem!
//       }
//    
//    private func fetchUserFiles() {
//            showActivityIndicator()
//            fileFirebaseService.fetchUserFiles(userRole: userRole) { [weak self] result in
//                DispatchQueue.main.async {
//                    self?.hideActivityIndicator()
//                }
//                switch result {
//                case .success(let fetchedFiles):
//                    self?.files = fetchedFiles
//                    DispatchQueue.main.async {
//                        self?.collectionView.reloadData()
//                        if fetchedFiles.isEmpty {
//                            self?.setEmptyMessage("沒有文件")
//                        } else {
//                            self?.restoreTableView()
//                        }
//                    }
//                case .failure(let error):
//                    DispatchQueue.main.async {
//                        self?.setEmptyMessage("無法加載文件")
//                        self?.showAlert(title: "錯誤", message: error.localizedDescription)
//                    }
//                }
//            }
//        }
//    
//    func setupFirestoreListener(for currentUserID: String) {
//        let collectionPath = "files"
//        let queryField = userRole == .teacher ? "ownerID" : "authorizedStudents"
//
//        let query = userRole == .teacher ?
//        FileFirebaseService.firestore.collection(collectionPath).whereField(queryField, isEqualTo: currentUserID) :
//        FileFirebaseService.firestore.collection(collectionPath).whereField(queryField, arrayContains: currentUserID)
//        
//        query.addSnapshotListener { [weak self] (snapshot, error) in
//            if let error = error {
//                print("Error fetching user files: \(error.localizedDescription)")
//                self?.setCustomEmptyStateView() 
//                return
//            }
//
//            guard let snapshot = snapshot else {
//                print("No snapshot received.")
//                self?.files.removeAll()
//                self?.collectionView.reloadData()
//                self?.setCustomEmptyStateView() // 顯示自定義的 empty state
//                return
//            }
//
//            // 處理即時變動的文件
//            self?.handleFetchedFiles(snapshot)
//        }
//    }
//    
//    func getCachedFiles() -> [FileItem] {
//        let fileManager = FileManager.default
//        let cacheDirectory = fileFirebaseService.getCacheDirectory()
//
//        do {
//            let fileURLs = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
//            var cachedFiles: [FileItem] = []
//
//            for fileURL in fileURLs {
//                let fileName = fileURL.lastPathComponent
//                let fileItem = FileItem(localURL: fileURL, remoteURL: fileURL, downloadURL: "", fileName: fileName, storagePath: "files/\(fileName)")
//                cachedFiles.append(fileItem)
//            }
//            return cachedFiles
//        } catch {
//            print("Error fetching cached files: \(error.localizedDescription)")
//            return []
//        }
//    }
//    
//    private func handleFetchedFiles(_ snapshot: QuerySnapshot?) {
//        guard let documents = snapshot?.documents else {
//            print("No files found.")
//            self.files.removeAll()
//            self.collectionView.reloadData()
//            setCustomEmptyStateView() // 設置自定義的 empty state
//            return
//        }
//
//        // 創建一個臨時的文件列表
//        var updatedFiles: [FileItem] = []
//        self.fileDownloadStatus.removeAll()
//        self.fileURLs.removeAll()
//
//        for document in documents {
//            guard let urlString = document.data()["downloadURL"] as? String,
//                  let fileName = document.data()["fileName"] as? String,
//                  let remoteURL = URL(string: urlString) else {
//                continue
//            }
//
//            // 檢查本地緩存
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
//                // 刷新 collectionView 以顯示活動指示器
//                DispatchQueue.main.async {
//                    self.collectionView.reloadData()
//                }
//
//                self.downloadFile(from: remoteURL, withName: fileName)
//            }
//        }
//
//        // 更新 self.files
//        self.files = updatedFiles
//
//        DispatchQueue.main.async {
//            self.collectionView.reloadData()
//            if self.files.isEmpty {
//                self.setCustomEmptyStateView() // 顯示自定義的 empty state 視圖
//            } else {
//                self.restoreCollectionView()  // 恢復正常背景
//            }
//        }
//    }
//    
//    func setupCollectionView() {
//        
//        let layout = UICollectionViewFlowLayout()
//        
//        // 設置每行顯示的單元格數量
//        let numberOfItemsPerRow: CGFloat = 3
//        // 設置單元格之間的間距
//        let spacing: CGFloat = 10
//        
//        // 計算每個單元格的寬度
//        let totalSpacing = (2 * spacing) + ((numberOfItemsPerRow - 1) * spacing) // 頁面左右和單元格之間的總間距
//        let itemWidth = (view.bounds.width - totalSpacing) / numberOfItemsPerRow
//        
//        layout.itemSize = CGSize(width: itemWidth, height: itemWidth + 20) // 調整高度以容納標籤
//        layout.sectionInset = UIEdgeInsets(top: spacing, left: spacing, bottom: spacing, right: spacing)
//        layout.minimumInteritemSpacing = spacing
//        layout.minimumLineSpacing = spacing
//        
//        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
//        collectionView.delegate = self
//        collectionView.dataSource = self
//        collectionView.allowsMultipleSelection = false
//        collectionView.register(FileCell.self, forCellWithReuseIdentifier: "fileCell")
//        collectionView.backgroundColor = .myBackground
//        view.addSubview(collectionView)
//        
//        collectionView.translatesAutoresizingMaskIntoConstraints = false
//        
//        collectionViewBottomConstraint = collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
//        
//        NSLayoutConstraint.activate([
//            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
//            collectionView.leftAnchor.constraint(equalTo: view.leftAnchor),
//            collectionView.rightAnchor.constraint(equalTo: view.rightAnchor),
//            collectionViewBottomConstraint
//        ])
//        
//        updateCollectionViewConstraints()
//    }
//    
//    func updateCollectionViewConstraints() {
//        if userRole == .student {
//            collectionViewBottomConstraint.constant = 0
//        } else {
//            collectionViewBottomConstraint.constant = -300
//        }
//    }
//    
////    func uploadAllFiles() {
////        for fileItem in files {
////            guard let localURL = fileItem.localURL else {
////                print("File \(fileItem.fileName) 已經上傳，跳過。")
////                continue
////            }
////            
////            uploadFileToFirebase(localURL, fileName: fileItem.fileName) { [weak self] result in
////                switch result {
////                case .success(let downloadURL):
////                    self?.saveFileMetadataToFirestore(downloadURL: downloadURL, fileName: fileItem.fileName)
////                case .failure(let error):
////                    print("File upload failed for \(fileItem.fileName): \(error.localizedDescription)")
////                }
////            }
////        }
////    }
//    
//    @objc func uploadFiles() {
//        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.item])
//        documentPicker.delegate = self
//        present(documentPicker, animated: true, completion: nil)
//    }
//    
//    // MARK: - 文件上傳到 Firebase
//    func generateUniqueFileName(originalName: String) -> String {
//        let uuid = UUID().uuidString
//        return "\(uuid)_\(originalName)"
//    }
//    
//    func setupLongPressGesture() {
//        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
//        collectionView.addGestureRecognizer(longPressGesture)
//    }
//    
//    @objc func handleLongPress(gesture: UILongPressGestureRecognizer) {
//        let point = gesture.location(in: collectionView)
//        if let indexPath = collectionView.indexPathForItem(at: point) {
//            editFileName(at: indexPath)
//        }
//    }
//    
//    func updateFileName(at indexPath: IndexPath, newName: String) {
//        var fileItem = files[indexPath.item]
//        
//        // 生成新的文件名
//        let newFileName = newName
//        
//        // 更新本地文件名稱（如果有本地文件）
//        if let localURL = fileItem.localURL {
//            let newLocalURL = localURL.deletingLastPathComponent().appendingPathComponent(newFileName)
//            
//            do {
//                // 重命名本地文件
//                try FileManager.default.moveItem(at: localURL, to: newLocalURL)
//                
//                // 更新文件數據
//                fileItem = FileItem(localURL: newLocalURL, remoteURL: fileItem.remoteURL, downloadURL: fileItem.downloadURL, fileName: newFileName)
//                files[indexPath.item] = fileItem
//            } catch {
//                print("Error renaming local file: \(error.localizedDescription)")
//                showAlert(title: "重命名失敗", message: "無法重命名本地文件。")
//                return
//            }
//        }
//        
//        // 更新 Firestore 中的文件名稱
//        FileFirebaseService.updateFileMetadataInFirestore(for: fileItem, newFileName: newFileName)
//        
//        // 重新載入 CollectionView
//        collectionView.reloadItems(at: [indexPath])
//    }
//    
//    // MARK: - Cache
//    
//    
//    func isFileCached(fileName: String) -> URL? {
//        let filePath = getCacheDirectory().appendingPathComponent(fileName)
//        if FileManager.default.fileExists(atPath: filePath.path) {
//            return filePath
//        }
//        return nil
//    }
//}
//
//extension FilesVC: UITableViewDelegate, UITableViewDataSource {
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return studentInfos.count
//    }
//    
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell: StudentTableViewCell = tableView.dequeueReusableCell(withIdentifier: "StudentCell", for: indexPath) 
//        cell.backgroundColor = .myBackground
//        let student = studentInfos[indexPath.row]
//        cell.configure(with: student)
//        
//        if selectedStudentIDs.contains(student.id) {
//            let checkmark = UIImageView(image: UIImage(systemName: "checkmark"))
//            checkmark.tintColor = .mainOrange
//            cell.accessoryView = checkmark
//        } else {
//            cell.accessoryView = nil
//        }
//        
//        cell.selectionStyle = .none
//        
//        return cell
//    }
//    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let student = studentInfos[indexPath.row]
//        if selectedStudentIDs.contains(student.id) {
//            selectedStudentIDs.remove(student.id)
//        } else {
//            selectedStudentIDs.insert(student.id)
//        }
//        
//        tableView.reloadRows(at: [indexPath], with: .automatic)
//        
//        updateSendButtonState()
//    }
//}
//
//extension FilesVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return files.count
//    }
//    
////    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
////        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "fileCell", for: indexPath) as! FileCell
////        let fileItem = files[indexPath.item]
////        cell.delegate = self
////
////        if let isDownloading = fileDownloadStatus[fileItem.remoteURL] {
////            cell.configure(with: fileItem, isDownloading: isDownloading, allowsMultipleSelection: collectionView.allowsMultipleSelection)
////        } else {
////            cell.configure(with: fileItem, isDownloading: false, allowsMultipleSelection: collectionView.allowsMultipleSelection)
////        }
////        
////        if let progress = fileDownloadProgress[fileItem.remoteURL] {
////            cell.updateProgress(progress)
////        } else {
////            cell.updateProgress(0.0)
////        }
////        
////        return cell
////    }
//    
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let cell: FileCell = collectionView.dequeueReusableCell(withReuseIdentifier: "fileCell", for: indexPath)
//        let fileItem = files[indexPath.item]
//        cell.delegate = self
//
//        var isDownloading = false
//        var progress: Float = 0.0
//
//        if let isFileDownloading = fileDownloadStatus[fileItem.remoteURL] {
//            isDownloading = isFileDownloading
//        }
//
//        if let downloadProgress = fileDownloadProgress[fileItem.remoteURL] {
//            progress = downloadProgress
//        }
//
//        cell.configure(with: fileItem, isDownloading: isDownloading, allowsMultipleSelection: collectionView.allowsMultipleSelection)
//        cell.updateProgress(progress)
//
//        return cell
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        if indexPath.item < files.count {
//            let fileItem = files[indexPath.item]
//            
//            if collectionView.allowsMultipleSelection {
//                selectedFiles.append(fileItem)
//                print("選擇文件：\(fileItem.fileName)")
//                updateSendButtonState()
//            } else {
//                if let localURL = fileItem.localURL {
//                    previewFile(at: localURL)
//                } else {
//                    showAlert(title: "無法預覽", message: "文件尚未下載完成。")
//                }
//            }
//        }
//    }
//
//    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
//        if indexPath.item < files.count {
//            let deselectedFileItem = files[indexPath.item]
//            
//            if collectionView.allowsMultipleSelection {
//                // 使用 FileItem 的 remoteURL 來查找對應的文件
//                if let index = selectedFiles.firstIndex(where: { $0.remoteURL == deselectedFileItem.remoteURL }) {
//                    selectedFiles.remove(at: index)
//                }
//                
//                print("取消選擇文件：\(deselectedFileItem.fileName)")
//                updateSendButtonState()
//            }
//        }
//    }
//}
//
//extension FilesVC: FileCellDelegate {
//    func fileCellDidRequestDelete(_ cell: FileCell) {
//        guard let indexPath = collectionView.indexPath(for: cell) else { return }
//        let fileItem = files[indexPath.item]
//        
//        let alert = UIAlertController(title: "刪除文件", message: "確定要刪除文件 \(fileItem.fileName) 嗎？", preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "刪除", style: .destructive, handler: { [weak self] _ in
//            self?.deleteFile(at: indexPath)
//        }))
//        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
//        present(alert, animated: true, completion: nil)
//    }
//    
//    func fileCellDidRequestEditName(_ cell: FileCell) {
//        guard let indexPath = collectionView.indexPath(for: cell) else { return }
//        editFileName(at: indexPath)
//    }
//
//    func editFileName(at indexPath: IndexPath) {
//        let fileItem = files[indexPath.item]
//        let alertController = UIAlertController(title: "編輯文件名稱", message: "請輸入新的文件名稱", preferredStyle: .alert)
//        
//        alertController.addTextField { textField in
//            textField.text = fileItem.fileName 
//        }
//
//        let confirmAction = UIAlertAction(title: "確定", style: .default) { [weak self] _ in
//            if let newFileName = alertController.textFields?.first?.text, !newFileName.isEmpty {
//                self?.updateFileName(at: indexPath, newName: newFileName)
//            }
//        }
//        
//        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
//        
//        alertController.addAction(confirmAction)
//        alertController.addAction(cancelAction)
//
//        present(alertController, animated: true, completion: nil)
//    }
//    
//    func deleteFile(at indexPath: IndexPath) {
//        guard indexPath.item < files.count else {
//            print("Error: Index out of range.")
//            return
//        }
//        
//        let fileItem = files[indexPath.item]
//        guard let storagePath = fileItem.storagePath, !storagePath.isEmpty else {
//            print("Error: storagePath is nil or empty.")
//            showAlert(title: "刪除失敗", message: "無法刪除文件，文件的存储路径无效。")
//            return
//        }
//        
//        print("Storage Path: \(storagePath)")
//        print("Local URL: \(String(describing: fileItem.localURL))")
//        print("Remote URL: \(fileItem.remoteURL)")
//        
//        let storageRef = fileFirebaseService.storage.reference().child(storagePath)
//        
//        storageRef.delete { [weak self] error in
//            if let error = error {
//                print("Error deleting file from Storage: \(error.localizedDescription)")
//                self?.showAlert(title: "刪除失敗", message: "無法刪除文件，請稍後再試。")
//                return
//            }
//            
//            self?.firestore.collection("files")
//                .whereField("storagePath", isEqualTo: storagePath)
//                .getDocuments { snapshot, error in
//                    if let error = error {
//                        print("Error deleting file metadata from Firestore: \(error.localizedDescription)")
//                        return
//                    }
//                    
//                    guard let document = snapshot?.documents.first else {
//                        print("File not found in Firestore.")
//                        return
//                    }
//                    
//                    document.reference.delete { error in
//                        if let error = error {
//                            print("Error deleting file metadata from Firestore: \(error.localizedDescription)")
//                        } else {
//                            print("Successfully deleted metadata for file: \(fileItem.fileName)")
//                            
//                            // 删除本地缓存的文件
//                            do {
//                                if let localURL = fileItem.localURL, FileManager.default.fileExists(atPath: localURL.path) {
//                                    try FileManager.default.removeItem(at: localURL)
//                                    print("Local file deleted successfully.")
//                                }
//                            } catch {
//                                print("Error deleting local file: \(error.localizedDescription)")
//                            }
//                            
//                            DispatchQueue.main.async { [weak self] in
//                                guard let self = self else { return }
//                                if let currentIndex = self.files.firstIndex(where: { $0.fileName == fileItem.fileName && $0.remoteURL == fileItem.remoteURL }) {
//                                    self.files.remove(at: currentIndex)
//                                    self.collectionView.deleteItems(at: [IndexPath(item: currentIndex, section: 0)])
//                                    
//                                    if self.files.isEmpty {
//                                        self.setCustomEmptyStateView()
//                                    }
//                                } else {
//                                    self.collectionView.reloadData()
//                                }
//                            }
//                        }
//                    }
//                }
//        }
//    }
//}
//
//extension FilesVC: UIDocumentPickerDelegate {
//    
//    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
//        guard let selectedURL = urls.first else { return }
//        let fileName = selectedURL.lastPathComponent
//        
//        checkIfFileExists(fileName: fileName) { [weak self] exists in
//            if exists {
//                DispatchQueue.main.async {
//                    self?.showAlert(title: "檔案已存在", message: "已存在同名檔案，請選擇其他檔案或更改檔案名稱。")
//                }
//            } else {
//                fileFirebaseService.uploadFileToFirebase(fileURL, fileName: fileName) { [weak self] result in
//                        self?.hideActivityIndicator()
//                        switch result {
//                        case .success(let downloadURL):
//                            print("File uploaded successfully: \(downloadURL)")
//                            DispatchQueue.main.async {
//                                self?.collectionView.reloadData()
//                            }
//                        case .failure(let error):
//                            print("Error uploading file: \(error.localizedDescription)")
//                            self?.showAlert(title: "錯誤", message: "文件上傳失敗，請稍後再試。")
//                        }
//                    }
//            }
//        }
//    }
//    
//    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
//        print("用戶取消了文件選擇。")
//    }
//    
//    func checkIfFileExists(fileName: String, completion: @escaping (Bool) -> Void) {
//        guard let currentUserID = UserSession.shared.currentUserID else {
//            completion(false)
//            return
//        }
//        
//        FileFirebaseService.firestore.collection("files")
//            .whereField("fileName", isEqualTo: fileName)
//            .whereField("ownerID", isEqualTo: currentUserID)
//            .getDocuments { snapshot, error in
//                if let error = error {
//                    print("Error checking if file exists: \(error.localizedDescription)")
//                    completion(false)
//                    return
//                }
//                
//                if let documents = snapshot?.documents, !documents.isEmpty {
//                    // 檔案已存在
//                    completion(true)
//                } else {
//                    // 檔案不存在
//                    completion(false)
//                }
//            }
//    }
//}
//
//// MARK: - Empty State
//extension FilesVC {
//    func setCustomEmptyStateView() {
//        let emptyStateView = UIView(frame: collectionView.bounds)
//        
//        let imageView = UIImageView(image: UIImage(systemName: "doc.text"))
//        imageView.tintColor = .myGray
//        imageView.translatesAutoresizingMaskIntoConstraints = false
//        emptyStateView.addSubview(imageView)
//        
//        let messageLabel = UILabel()
//        messageLabel.text = userRole == .student ? "還沒有老師分享教材給你喔" : "沒有文件，請點擊右上角上傳文件"
//        messageLabel.textColor = .myGray
//        messageLabel.numberOfLines = 0
//        messageLabel.textAlignment = .center
//        messageLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
//        messageLabel.translatesAutoresizingMaskIntoConstraints = false
//        emptyStateView.addSubview(messageLabel)
//        
//        NSLayoutConstraint.activate([
//            imageView.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
//            imageView.centerYAnchor.constraint(equalTo: emptyStateView.centerYAnchor, constant: -20),
//            imageView.widthAnchor.constraint(equalToConstant: 80),
//            imageView.heightAnchor.constraint(equalToConstant: 80),
//            
//            messageLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
//            messageLabel.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor, constant: 20),
//            messageLabel.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor, constant: -20)
//        ])
//        
//        collectionView.backgroundView = emptyStateView
//    }
//    
//    func restoreCollectionView() {
//        collectionView.backgroundView = nil
//    }
//}
//
//// MARK: - Alert Helper
//extension FilesVC {
//    func showAlert(title: String, message: String) {
//        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
//        present(alert, animated: true, completion: nil)
//    }
//}
//
//extension FilesVC: URLSessionDownloadDelegate {
//
//    func downloadFile(from url: URL, withName fileName: String) {
//        let sessionConfig = URLSessionConfiguration.default
//        let session = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
//        let task = session.downloadTask(with: url)
//        task.resume()
//    }
//
//    // MARK: - URLSessionDownloadDelegate 方法
//
//    // 下载进度更新
//    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
//                    didWriteData bytesWritten: Int64,
//                    totalBytesWritten: Int64,
//                    totalBytesExpectedToWrite: Int64) {
//        guard let url = downloadTask.originalRequest?.url else { return }
//
//        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
//        DispatchQueue.main.async {
//            self.updateDownloadProgress(for: url, progress: progress)
//        }
//    }
//
//    // 下载完成
//    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
//                    didFinishDownloadingTo location: URL) {
//        guard let url = downloadTask.originalRequest?.url else { return }
//        let fileName = url.lastPathComponent
//        let cacheDirectory = fileFirebaseService.getCacheDirectory()
//        let localUrl = cacheDirectory.appendingPathComponent(fileName)
//
//        do {
//            if FileManager.default.fileExists(atPath: localUrl.path) {
//                try FileManager.default.removeItem(at: localUrl)
//            }
//            try FileManager.default.moveItem(at: location, to: localUrl)
//
//            DispatchQueue.main.async {
//                if let index = self.files.firstIndex(where: { $0.remoteURL == url }) {
//                    let updatedFileItem = FileItem(localURL: localUrl,
//                                                   remoteURL: url,
//                                                   downloadURL: self.files[index].downloadURL,
//                                                   fileName: self.files[index].fileName)
//                    self.files[index] = updatedFileItem
//                    self.fileDownloadStatus[url] = false
//
//                    self.fileDownloadProgress.removeValue(forKey: url)
//
//                    self.collectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
//                }
//            }
//        } catch {
//            print("移動文件時出錯: \(error.localizedDescription)")
//        }
//    }
//
//    // 更新下载进度
//    func updateDownloadProgress(for url: URL, progress: Double) {
//        if let index = files.firstIndex(where: { $0.remoteURL == url }) {
//            let indexPath = IndexPath(item: index, section: 0)
//
//            if let cell = collectionView.cellForItem(at: indexPath) as? FileCell {
//                cell.updateProgress(Float(progress))
//            }
//        }
//    }
//}
