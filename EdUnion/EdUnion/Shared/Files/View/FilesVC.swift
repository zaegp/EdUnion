//
//  FilesVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/26.
//

import UIKit
import FirebaseStorage
import FirebaseFirestore

//class FilesVC: UIViewController, UIDocumentInteractionControllerDelegate {
//    var collectionView: UICollectionView!
//    var selectedFiles: [URL] = []
//    var files: [File] = []
//    var documentInteractionController: UIDocumentInteractionController?
//    
//    var fileURLs: [URL: String] = [:]
//    var fileDownloadStatus: [URL: Bool] = [:]
//    
//    let storage = Storage.storage()
//    let firestore = Firestore.firestore()
//    let userID = UserSession.shared.currentUserID
//    var studentTableView: UITableView!
//    var studentInfos: [Student] = []
//    var selectedStudentIDs: Set<String> = []
//    var sendButton: UIButton!
//    var currentUploadTask: StorageUploadTask?
//    
//    var userRole: String = UserDefaults.standard.string(forKey: "userRole") ?? "student"
//    
//    var collectionViewBottomConstraint: NSLayoutConstraint!
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        view.backgroundColor = .myBackground
//        
//        setupCollectionView()
//        
//        if userRole == "teacher" {
//            setupSendButton()
//            setupStudentTableView()
//            setupLongPressGesture()
//            setupMenu()
//            uploadAllFiles()
//            updateStudentTableViewEmptyState()
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
//        
//        fetchStudentsNotes(forTeacherID: userID ?? "") { [weak self] notes in
//            for (studentID, _) in notes {
//                self?.fetchUser(from: "students", userID: studentID, as: Student.self)
//            }
//        }
//    }
//    
//    func setEmptyMessage(_ message: String) {
//            let messageLabel = UILabel()
//            messageLabel.text = message
//            messageLabel.textColor = .myGray
//            messageLabel.numberOfLines = 0
//            messageLabel.textAlignment = .center
//            messageLabel.font = UIFont.systemFont(ofSize: 20, weight: .medium)
//            messageLabel.sizeToFit()
//            
//            studentTableView.backgroundView = messageLabel
//            studentTableView.separatorStyle = .none
//        }
//        
//        func restoreTableView() {
//            studentTableView.backgroundView = nil
//            studentTableView.separatorStyle = .singleLine
//        }
//    
//    func updateStudentTableViewEmptyState() {
//            if studentInfos.isEmpty {
//                setEmptyMessage("還沒有學生可以分享，快去上課吧！")
//            } else {
//                restoreTableView()
//            }
//        }
//    
//    @objc func selectMultipleFilesForSharing() {
//        collectionView.allowsMultipleSelection = true
//        sendButton.isHidden = false
//       updateSendButtonState()
//        studentTableView.isHidden = false
//    }
//    
//    func fetchStudentsNotes(completion: @escaping ([String: String]) -> Void) {
//        firestore.collection("teachers").document(userID ?? "").getDocument { (snapshot, error) in
//            if let error = error {
//                print("Error fetching studentsNotes: \(error.localizedDescription)")
//                completion([:])
//                return
//            }
//            
//            guard let data = snapshot?.data(), let studentsNotes = data["studentsNotes"] as? [String: String] else {
//                print("No studentsNotes found for teacher \(self.userID)")
//                completion([:])
//                return
//            }
//            
//            completion(studentsNotes)
//        }
//    }
//    
//    func fetchStudentsNotes(forTeacherID teacherID: String, completion: @escaping ([String: String]) -> Void) {
//        firestore.collection("teachers").document(teacherID).getDocument { (snapshot, error) in
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
//    func fetchUser<T: UserProtocol & Decodable>(from collection: String, userID: String, as type: T.Type) {
//        UserFirebaseService.shared.fetchUser(from: collection, by: userID, as: type) { [weak self] result in
//            switch result {
//            case .success(let user):
//                if let student = user as? Student {
//                    self?.studentInfos.append(student)
//                }
//                DispatchQueue.main.async {
//                    self?.studentTableView.reloadData()
//                    self?.updateStudentTableViewEmptyState()
//                }
//            case .failure(let error):
//                print("Error fetching user: \(error.localizedDescription)")
//            }
//        }
//    }
//    
//    @objc func sendFilesToSelectedStudents() {
//        guard !selectedFiles.isEmpty, !selectedStudentIDs.isEmpty else {
//            print("沒有選擇任何文件或學生")
//            return
//        }
//        
//        // 動畫開始
//        startSendAnimation()
//        
//        // 模擬文件傳送操作，這裡添加一些延遲來模擬實際傳送
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
//            for studentID in self.selectedStudentIDs {
//                for file in self.selectedFiles {
//                    print("發送文件 \(file.lastPathComponent) 給學生 \(studentID)")
//                    
//                    let fileName = file.lastPathComponent
//                    
//                    self.firestore.collection("files")
//                        .whereField("fileName", isEqualTo: fileName)
//                        .getDocuments { (snapshot, error) in
//                            if let error = error {
//                                print("Error finding file in Firestore: \(error.localizedDescription)")
//                                return
//                            }
//                            
//                            guard let document = snapshot?.documents.first else {
//                                print("File not found in Firestore.")
//                                return
//                            }
//                            
//                            document.reference.updateData([
//                                "authorizedStudents": FieldValue.arrayUnion([studentID])
//                            ]) { error in
//                                if let error = error {
//                                    print("Error adding student to authorized list: \(error)")
//                                } else {
//                                    print("Student \(studentID) added to authorized list for file \(fileName) successfully.")
//                                }
//                            }
//                        }
//                }
//            }
//            
//           
//            self.selectedFiles.removeAll()
//            self.selectedStudentIDs.removeAll()
//            self.studentTableView.isHidden = true
//            self.sendButton.isHidden = true
//            self.collectionView.allowsMultipleSelection = false
//            self.collectionView.reloadData()
//            
//            // 動畫結束
//            self.endSendAnimation()
//        }
//    }
//
//    func startSendAnimation() {
//        // 創建飛機圖標
//        let planeImageView = UIImageView(image: UIImage(systemName: "paperplane.fill"))
//        planeImageView.tintColor = .mainOrange
//        planeImageView.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(planeImageView)
//        
//        // 設置飛機圖標的位置
//        NSLayoutConstraint.activate([
//            planeImageView.centerXAnchor.constraint(equalTo: sendButton.centerXAnchor),
//            planeImageView.centerYAnchor.constraint(equalTo: sendButton.centerYAnchor),
//            planeImageView.widthAnchor.constraint(equalToConstant: 30),
//            planeImageView.heightAnchor.constraint(equalToConstant: 30)
//        ])
//        
//        // 飛機飛走的動畫
//        UIView.animate(withDuration: 1.0, animations: {
//            planeImageView.transform = CGAffineTransform(translationX: self.view.frame.width, y: -self.view.frame.height / 2)
//            planeImageView.alpha = 0
//        }, completion: { _ in
//            planeImageView.removeFromSuperview()
//            
//            // 顯示勾選圖標動畫
//            self.showCheckmarkAnimation()
//        })
//    }
//
//    func showCheckmarkAnimation() {
//        // 創建勾選圖標
//        let checkmarkImageView = UIImageView(image: UIImage(systemName: "checkmark"))
//        checkmarkImageView.tintColor = .mainOrange
//        
//        checkmarkImageView.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(checkmarkImageView)
//        
//        // 設置勾選圖標的位置在螢幕中心
//        NSLayoutConstraint.activate([
//            checkmarkImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            checkmarkImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
//            checkmarkImageView.widthAnchor.constraint(equalToConstant: 100),
//            checkmarkImageView.heightAnchor.constraint(equalToConstant: 100)
//        ])
//        
//        // 動畫效果：從小到大出現
//        checkmarkImageView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
//        checkmarkImageView.alpha = 0
//        UIView.animate(withDuration: 0.5, animations: {
//            checkmarkImageView.transform = CGAffineTransform.identity
//            checkmarkImageView.alpha = 1
//        }, completion: { _ in
//            // 延遲 1 秒後淡出並移除
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
//        sendButton.backgroundColor = canSend ? .mainOrange : .gray // 根據狀態改變背景色
//    }
//    
//    private func previewFile(at url: URL) {
//        if FileManager.default.fileExists(atPath: url.path) {
//            documentInteractionController = UIDocumentInteractionController(url: url)
//            documentInteractionController?.delegate = self
//            documentInteractionController?.presentPreview(animated: true)
//        } else {
//            print("File does not exist at path: \(url.path)")
//        }
//    }
//    
//    func fetchUserFiles() {
//        guard let currentUserID = UserSession.shared.currentUserID else {
//            print("Error: Current user ID is nil.")
//            return
//        }
//        
//        let cachedFiles = getCachedFiles()
//        if !cachedFiles.isEmpty {
//            self.files = cachedFiles
//            DispatchQueue.main.async {
//                self.collectionView.reloadData()
//            }
//        }
//        
//        let collectionPath = "files"
//        let queryField = userRole == "teacher" ? "ownerID" : "authorizedStudents"
//        
//        // 即時監聽文件變動
//        let query = userRole == "teacher" ?
//            firestore.collection(collectionPath).whereField(queryField, isEqualTo: currentUserID) :
//            firestore.collection(collectionPath).whereField(queryField, arrayContains: currentUserID)
//        
//        // 使用 Firestore 即時監聽文件變動
//        query.addSnapshotListener { [weak self] (snapshot, error) in
//            if let error = error {
//                print("Error fetching user files: \(error)")
//                return
//            }
//            
//            // 處理即時變動的文件
//            self?.handleFetchedFiles(snapshot)
//        }
//    }
//    
//    func getCachedFiles() -> [URL] {
//        let fileManager = FileManager.default
//        let cacheDirectory = getCacheDirectory()
//        
//        do {
//            let fileURLs = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
//            return fileURLs
//        } catch {
//            print("Error fetching cached files: \(error.localizedDescription)")
//            return []
//        }
//    }
//    
//    private func handleFetchedFiles(_ snapshot: QuerySnapshot?) {
//        guard let documents = snapshot?.documents else {
//            print("No files found.")
//            return
//        }
//        
//        self.files.removeAll()
//        self.fileDownloadStatus.removeAll()
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
//                // 文件已緩存，直接使用本地文件
//                self.files.append(cachedURL)
//                self.fileDownloadStatus[cachedURL] = false
//            } else {
//                // 文件未緩存，需要下載
//                self.files.append(remoteURL)
//                self.fileDownloadStatus[remoteURL] = true
//                
//                // 在此時刷新 collectionView，顯示活動指示器
//                DispatchQueue.main.async {
//                    self.collectionView.reloadData()
//                }
//                
//                self.downloadFile(from: remoteURL, withName: fileName)
//            }
//        }
//        
//        DispatchQueue.main.async {
//            self.collectionView.reloadData()
//        }
//    }
//    
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
//                        if let index = self?.files.firstIndex(of: url) {
//                            self?.files[index] = localUrl
//                        }
//                        self?.fileDownloadStatus[localUrl] = false
//                        self?.collectionView.reloadData()
//                    }
//                }
//            } catch {
//                print("Error moving file: \(error.localizedDescription)")
//            }
//        }
//        task.resume()
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
//                collectionView.delegate = self
//                collectionView.dataSource = self
//                collectionView.allowsMultipleSelection = false
//                collectionView.register(FileCell.self, forCellWithReuseIdentifier: "fileCell")
//                collectionView.backgroundColor = .myBackground
//                view.addSubview(collectionView)
//                
//                collectionView.translatesAutoresizingMaskIntoConstraints = false
//                
//                collectionViewBottomConstraint = collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
//                
//                NSLayoutConstraint.activate([
//                    collectionView.topAnchor.constraint(equalTo: view.topAnchor),
//                    collectionView.leftAnchor.constraint(equalTo: view.leftAnchor),
//                    collectionView.rightAnchor.constraint(equalTo: view.rightAnchor),
//                    collectionViewBottomConstraint
//                ])
//        
//        updateCollectionViewConstraints()
//    }
//    
//    func updateCollectionViewConstraints() {
//            if userRole == "student" {
//                collectionViewBottomConstraint.constant = 0
//            } else if userRole == "teacher" {
//                collectionViewBottomConstraint.constant = -500
//            }
//        }
//    
//    func uploadAllFiles() {
//        for file in files {
//            uploadFileToFirebase(file) { [weak self] result in
//                switch result {
//                case .success(let downloadURL):
//                    self?.saveFileMetadataToFirestore(downloadURL: downloadURL, fileName: file.lastPathComponent)
//                case .failure(let error):
//                    print("File upload failed: \(error.localizedDescription)")
//                }
//            }
//        }
//    }
//    
//    // MARK: - 文件上傳到 Firebase
//    func generateUniqueFileName(originalName: String) -> String {
//        let uuid = UUID().uuidString
//        return "\(uuid)_\(originalName)"
//    }
//    
//    func uploadFileToFirebase(_ fileURL: URL, retryCount: Int = 3, completion: @escaping (Result<String, Error>) -> Void) {
//        guard let currentUserID = UserSession.shared.currentUserID else {
//            print("Error: Current user ID is nil.")
//            completion(.failure(NSError(domain: "UserSession", code: -1, userInfo: [NSLocalizedDescriptionKey: "Current user ID is nil."])))
//            return
//        }
//        
//        let originalFileName = fileURL.lastPathComponent
//        let uniqueFileName = generateUniqueFileName(originalName: originalFileName)
//        let storageRef = Storage.storage().reference().child("files/\(uniqueFileName)")
//        
//        do {
//            let fileData = try Data(contentsOf: fileURL)
//            let metadata = StorageMetadata()
//            metadata.contentType = "application/octet-stream"
//            metadata.customMetadata = ["ownerId": currentUserID]
//            
//            print("Starting upload for file: \(uniqueFileName)")
//            
//            let uploadTask = storageRef.putData(fileData, metadata: metadata) { metadata, error in
//                if let error = error {
//                    if retryCount > 0 {
//                        print("Upload failed, retrying... (\(retryCount) retries left)")
//                        self.uploadFileToFirebase(fileURL, retryCount: retryCount - 1, completion: completion)
//                    } else {
//                        print("Upload failed with error: \(error.localizedDescription)")
//                        completion(.failure(error))
//                    }
//                    return
//                }
//                
//                print("Upload completed, fetching download URL.")
//                
//                storageRef.downloadURL { url, error in
//                    if let error = error {
//                        if retryCount > 0 {
//                            print("Download URL fetch failed, retrying... (\(retryCount) retries left)")
//                            self.uploadFileToFirebase(fileURL, retryCount: retryCount - 1, completion: completion)
//                        } else {
//                            print("Download URL fetch failed with error: \(error.localizedDescription)")
//                            completion(.failure(error))
//                        }
//                    } else if let url = url {
//                        print("Upload successful. Download URL: \(url.absoluteString)")
//                        completion(.success(url.absoluteString))
//                    }
//                }
//            }
//            
//            // 監控上傳進度
//            uploadTask.observe(.progress) { snapshot in
//                if let progress = snapshot.progress {
//                    let percentComplete = 100.0 * Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
//                    print("Upload is \(percentComplete)% complete.")
//                }
//            }
//            
//            uploadTask.observe(.failure) { snapshot in
//                if let error = snapshot.error {
//                    print("Upload failed during progress update: \(error.localizedDescription)")
//                    // 可選：在這裡呼叫 completion(.failure(error)) 或實現其他錯誤處理
//                }
//            }
//            
//            // 保持對 uploadTask 的強引用
//            self.currentUploadTask = uploadTask
//        } catch {
//            print("Error reading file data: \(error.localizedDescription)")
//            completion(.failure(error))
//        }
//    }
//    
//    @objc func uploadFiles() {
//        print("Upload button clicked.")
//        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.item])
//        documentPicker.delegate = self
//        present(documentPicker, animated: true, completion: nil)
//        
//        print("Document picker presented.")
//    }
//
//    func showAlert(title: String, message: String) {
//        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
//        present(alert, animated: true, completion: nil)
//    }
//    
//    func saveFileMetadataToFirestore(downloadURL: String, fileName: String) {
//        let currentUserID = UserSession.shared.currentUserID ?? "unknown_user"
//        let fileData: [String: Any] = [
//            "fileName": fileName,
//            "downloadURL": downloadURL,
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
//    func editFileName(at indexPath: IndexPath) {
//        let fileURL = files[indexPath.item]
//        let alertController = UIAlertController(title: "編輯文件名稱", message: "請輸入新的文件名稱", preferredStyle: .alert)
//        alertController.addTextField { textField in
//            textField.text = fileURL.lastPathComponent
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
//    func updateFileName(at indexPath: IndexPath, newName: String) {
//        var fileURL = files[indexPath.item]
//        
//        let newFileURL = fileURL.deletingLastPathComponent().appendingPathComponent(newName)
//        
//        files[indexPath.item] = newFileURL
//        
//        updateFileMetadataInFirestore(for: fileURL, newFileName: newName)
//        
//        // 重新載入CollectionView
//        collectionView.reloadItems(at: [indexPath])
//    }
//    
//    func updateFileMetadataInFirestore(for fileURL: URL, newFileName: String) {
//        // 查詢並更新 Firebase 中的文件名稱
//        firestore.collection("files").whereField("fileName", isEqualTo: fileURL.lastPathComponent).getDocuments { [weak self] (snapshot, error) in
//            if let error = error {
//                print("Error finding file in Firestore: \(error.localizedDescription)")
//                return
//            }
//            
//            guard let document = snapshot?.documents.first else {
//                print("File not found in Firestore.")
//                return
//            }
//            
//            // 更新文件名稱
//            document.reference.updateData(["fileName": newFileName]) { error in
//                if let error = error {
//                    print("Error updating file name in Firestore: \(error.localizedDescription)")
//                } else {
//                    print("File name updated successfully in Firestore.")
//                }
//            }
//        }
//    }
//    
//    // MARK: - Cache
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
//    // MARK: - UIDocumentInteractionControllerDelegate
//    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
//        return self
//    }
//}
//
//extension FilesVC: UITableViewDelegate, UITableViewDataSource {
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return studentInfos.count
//    }
//    
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "StudentCell", for: indexPath) as! StudentTableViewCell
//        cell.backgroundColor = .myBackground
//        let student = studentInfos[indexPath.row]
//        cell.configure(with: student)
//        
//        if selectedStudentIDs.contains(student.id) {
//                let checkmark = UIImageView(image: UIImage(systemName: "checkmark"))
//            checkmark.tintColor = .mainOrange
//                cell.accessoryView = checkmark
//            } else {
//                cell.accessoryView = nil
//            }
//        
//        cell.selectionStyle = .none
//        
//        return cell
//    }
//    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let student = studentInfos[indexPath.row]
//                if selectedStudentIDs.contains(student.id) {
//            selectedStudentIDs.remove(student.id)
//        } else {
//            selectedStudentIDs.insert(student.id)
//        }
//        
//        tableView.reloadRows(at: [indexPath], with: .automatic)
//        
//        updateSendButtonState()
//        
//    }
//}
//
//extension FilesVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return files.count
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "fileCell", for: indexPath) as! FileCell
//        if indexPath.item < files.count {
//            let fileURL = files[indexPath.item]
//            let isDownloading = fileDownloadStatus[fileURL] ?? false
//            cell.configure(with: fileURL, isDownloading: isDownloading)
//        }
//        return cell
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        if indexPath.item < files.count {
//            let selectedFileURL = files[indexPath.item]
//            
//            if collectionView.allowsMultipleSelection {
//                selectedFiles.append(selectedFileURL)
//                if let cell = collectionView.cellForItem(at: indexPath) as? FileCell {
//                    cell.setSelected(true)
//                }
//                print("選擇文件：\(selectedFileURL.lastPathComponent)")
//                updateSendButtonState()
//            } else {
//                previewFile(at: selectedFileURL)
//            }
//        }
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
//        if indexPath.item < files.count {
//            let deselectedFileURL = files[indexPath.item]
//            
//            if collectionView.allowsMultipleSelection {
//                if let index = selectedFiles.firstIndex(of: deselectedFileURL) {
//                    selectedFiles.remove(at: index)
//                    print("取消選擇文件：\(deselectedFileURL.lastPathComponent)")
//                }
//                if let cell = collectionView.cellForItem(at: indexPath) as? FileCell {
//                    cell.setSelected(false)
//                }
//            }
//            
//            updateSendButtonState()
//        }
//    }
//}
//
//// MARK: - UIDocumentPickerDelegate
//extension FilesVC: UIDocumentPickerDelegate {
//   func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
//    print("Document picker did pick documents: \(urls)")
//    
//    if urls.isEmpty {
//        print("Error: No files were selected.")
//        showAlert(title: "選擇錯誤", message: "沒有選擇任何文件。")
//        return
//    }
//    
//    let selectedURL = urls[0]
//    let fileName = selectedURL.lastPathComponent
//    
//    checkIfFileExists(fileName: fileName) { [weak self] exists in
//        if exists {
//            print("Error: A file with the same name already exists.")
//            self?.showAlert(title: "文件已存在", message: "已有同名文件，請重新選擇。")
//        } else {
//            self?.files.append(selectedURL)
//            self?.collectionView.reloadData()
//            self?.uploadFileToFirebase(selectedURL) { result in
//                switch result {
//                case .success(let downloadURL):
//                    self?.saveFileMetadataToFirestore(downloadURL: downloadURL, fileName: fileName)
//                    DispatchQueue.main.async {
//                        self?.showAlert(title: "上傳成功", message: "文件已成功上傳。")
//                    }
//                case .failure(let error):
//                    print("File upload failed: \(error.localizedDescription)")
//                    self?.showAlert(title: "上傳失敗", message: "文件上傳失敗，請稍後再試。")
//                }
//            }
//        }
//    }
//}
//    
//    func checkIfFileExists(fileName: String, completion: @escaping (Bool) -> Void) {
//        let currentUserID = UserSession.shared.currentUserID ?? "unknown_user"
//        firestore.collection("files")
//            .whereField("ownerID", isEqualTo: currentUserID)
//            .whereField("fileName", isEqualTo: fileName)
//            .getDocuments { snapshot, error in
//                if let error = error {
//                    print("Error checking file existence: \(error)")
//                    completion(false)
//                } else if let snapshot = snapshot, !snapshot.isEmpty {
//                    completion(true)
//                } else {
//                    completion(false)
//                }
//            }
//    }
//    
//    func showAlert(message: String) {
//        let alert = UIAlertController(title: "已有同名文件", message: message, preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
//        present(alert, animated: true, completion: nil)
//    }
//    
//    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
//        print("Document picker was cancelled")
//    }
//}
//
//
//extension FilesVC: UICollectionViewDelegate {
//    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
//        guard userRole == "teacher" else { return nil }
//        
//        let file = files[indexPath.item]
//        
//        return UIContextMenuConfiguration(identifier: indexPath as NSCopying, previewProvider: nil) { suggestedActions in
//            // 創建刪除動作
//            let deleteAction = UIAction(title: "刪除", image: UIImage(systemName: "trash"), attributes: .destructive) { action in
//                self.confirmDeleteFile(at: indexPath)
//            }
//            
//            return UIMenu(title: "", children: [deleteAction])
//        }
//    }
//}
//
//extension FilesVC {
//    func confirmDeleteFile(at indexPath: IndexPath) {
//        let file = files[indexPath.item]
//        let fileName = file.fileName
//        
//        let alert = UIAlertController(title: "刪除文件", message: "確定要刪除文件 \(fileName) 嗎？", preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "確定", style: .destructive, handler: { _ in
//            self.deleteFile(at: indexPath)
//        }))
//        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
//        
//        present(alert, animated: true, completion: nil)
//    }
//    
//    func deleteFile(at indexPath: IndexPath) {
//        let file = files[indexPath.item]
//        let fileName = file.fileName
//        let downloadURL = file.downloadURL
//        let fileID = file.id
//        
//        // 刪除 Firebase Storage 中的文件
//        let storageRef = Storage.storage().reference(forURL: downloadURL)
//        storageRef.delete { error in
//            if let error = error {
//                print("刪除 Storage 文件失敗: \(error.localizedDescription)")
//                self.showAlert(title: "刪除失敗", message: "無法刪除文件，請稍後再試。")
//                return
//            }
//            
//            print("文件已從 Storage 刪除。")
//            
//            // 從 Firestore 刪除文件文檔
//            self.firestore.collection("files").document(fileID).delete { error in
//                if let error = error {
//                    print("刪除 Firestore 文檔失敗: \(error.localizedDescription)")
//                    self.showAlert(title: "刪除失敗", message: "無法刪除文件的 Firestore 文檔。")
//                    return
//                }
//                
//                print("文件文檔已從 Firestore 刪除。")
//                
//                // 從本地數據源中移除文件
//                self.files.remove(at: indexPath.item)
//                self.collectionView.deleteItems(at: [indexPath])
//                
//                // 如果文件已被選中，移除選擇
//                if let selectedIndex = self.selectedFiles.firstIndex(where: { $0.fileName == fileName }) {
//                    self.selectedFiles.remove(at: selectedIndex)
//                    self.updateSendButtonState()
//                }
//                
//                self.showAlert(title: "刪除成功", message: "文件已成功刪除。")
//            }
//        }
//    }
//    
//    func showAlert(title: String, message: String) {
//        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "確定", style: .default, handler: nil))
//        present(alert, animated: true, completion: nil)
//    }
//}


class FilesVC: UIViewController, UIDocumentInteractionControllerDelegate, UIDocumentPickerDelegate {
    
    var collectionView: UICollectionView!
    var selectedFiles: [URL] = []
    var files: [URL] = []
    var documentInteractionController: UIDocumentInteractionController?
    
    var fileURLs: [URL: String] = [:]
    var fileDownloadStatus: [URL: Bool] = [:]
    
    let storage = Storage.storage()
    let firestore = Firestore.firestore()
    let userID = UserSession.shared.currentUserID
    var studentTableView: UITableView!
    var studentInfos: [Student] = []
    var selectedStudentIDs: Set<String> = []
    var sendButton: UIButton!
    var currentUploadTask: StorageUploadTask?
    
    var userRole: String = UserDefaults.standard.string(forKey: "userRole") ?? "student"
    
    var collectionViewBottomConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .myBackground
        
        setupCollectionView()
        
        if userRole == "teacher" {
            setupSendButton()
            setupStudentTableView()
            setupLongPressGesture()
            setupMenu()
            uploadAllFiles()
            updateStudentTableViewEmptyState()
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
    
    func updateStudentTableViewEmptyState() {
        if studentInfos.isEmpty {
            setEmptyMessage("還沒有學生可以分享，快去上課吧！")
        } else {
            restoreTableView()
        }
    }
    
    @objc func selectMultipleFilesForSharing() {
        collectionView.allowsMultipleSelection = true
        sendButton.isHidden = false
        updateSendButtonState()
        studentTableView.isHidden = false
    }
    
    func fetchStudentsNotes(completion: @escaping ([String: String]) -> Void) {
        firestore.collection("teachers").document(userID ?? "").getDocument { (snapshot, error) in
            if let error = error {
                print("Error fetching studentsNotes: \(error.localizedDescription)")
                completion([:])
                return
            }
            
            guard let data = snapshot?.data(), let studentsNotes = data["studentsNotes"] as? [String: String] else {
                print("No studentsNotes found for teacher \(self.userID)")
                completion([:])
                return
            }
            
            completion(studentsNotes)
        }
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
                    self?.updateStudentTableViewEmptyState()
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
        
        // 動畫開始
        startSendAnimation()
        
        // 模擬文件傳送操作，這裡添加一些延遲來模擬實際傳送
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            for studentID in self.selectedStudentIDs {
                for file in self.selectedFiles {
                    print("發送文件 \(file.lastPathComponent) 給學生 \(studentID)")
                    
                    let fileName = file.lastPathComponent
                    
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
            self.studentTableView.isHidden = true
            self.sendButton.isHidden = true
            self.collectionView.allowsMultipleSelection = false
            self.collectionView.reloadData()
            
            // 動畫結束
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
            documentInteractionController = UIDocumentInteractionController(url: url)
            documentInteractionController?.delegate = self
            documentInteractionController?.presentPreview(animated: true)
        } else {
            print("File does not exist at path: \(url.path)")
        }
    }
    
    func fetchUserFiles() {
        guard let currentUserID = UserSession.shared.currentUserID else {
            print("Error: Current user ID is nil.")
            return
        }
        
        let cachedFiles = getCachedFiles()
        if !cachedFiles.isEmpty {
            self.files = cachedFiles
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
        
        let collectionPath = "files"
        let queryField = userRole == "teacher" ? "ownerID" : "authorizedStudents"
        
        // 即時監聽文件變動
        let query = userRole == "teacher" ?
            firestore.collection(collectionPath).whereField(queryField, isEqualTo: currentUserID) :
            firestore.collection(collectionPath).whereField(queryField, arrayContains: currentUserID)
        
        // 使用 Firestore 即時監聽文件變動
        query.addSnapshotListener { [weak self] (snapshot, error) in
            if let error = error {
                print("Error fetching user files: \(error)")
                return
            }
            
            // 處理即時變動的文件
            self?.handleFetchedFiles(snapshot)
        }
    }
    
    func getCachedFiles() -> [URL] {
        let fileManager = FileManager.default
        let cacheDirectory = getCacheDirectory()
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            return fileURLs
        } catch {
            print("Error fetching cached files: \(error.localizedDescription)")
            return []
        }
    }
    
    private func handleFetchedFiles(_ snapshot: QuerySnapshot?) {
        guard let documents = snapshot?.documents else {
            print("No files found.")
            return
        }
        
        self.files.removeAll()
        self.fileDownloadStatus.removeAll()
        self.fileURLs.removeAll()
        
        for document in documents {
            guard let urlString = document.data()["downloadURL"] as? String,
                  let fileName = document.data()["fileName"] as? String,
                  let remoteURL = URL(string: urlString) else {
                continue
            }
            
            self.fileURLs[remoteURL] = fileName
            
            // 檢查本地緩存
            if let cachedURL = isFileCached(fileName: fileName) {
                // 文件已緩存，直接使用本地文件
                self.files.append(cachedURL)
                self.fileDownloadStatus[cachedURL] = false
            } else {
                // 文件未緩存，需要下載
                self.files.append(remoteURL)
                self.fileDownloadStatus[remoteURL] = true
                
                // 在此時刷新 collectionView，顯示活動指示器
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
                
                self.downloadFile(from: remoteURL, withName: fileName)
            }
        }
        
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    func downloadFile(from url: URL, withName fileName: String) {
        let task = URLSession.shared.downloadTask(with: url) { [weak self] (tempLocalUrl, response, error) in
            if let error = error {
                print("Error downloading file: \(error.localizedDescription)")
                return
            }
            
            guard let tempLocalUrl = tempLocalUrl else {
                print("Error: Temporary local URL is nil.")
                return
            }
            
            let cacheDirectory = self?.getCacheDirectory()
            let localUrl = cacheDirectory?.appendingPathComponent(fileName)
            
            do {
                if let localUrl = localUrl {
                    if FileManager.default.fileExists(atPath: localUrl.path) {
                        try FileManager.default.removeItem(at: localUrl)
                    }
                    try FileManager.default.moveItem(at: tempLocalUrl, to: localUrl)
                    
                    DispatchQueue.main.async {
                        // 更新 files 列表以指向本地緩存文件
                        if let index = self?.files.firstIndex(of: url) {
                            self?.files[index] = localUrl
                        }
                        self?.fileDownloadStatus[localUrl] = false
                        self?.collectionView.reloadData()
                    }
                }
            } catch {
                print("Error moving file: \(error.localizedDescription)")
            }
        }
        task.resume()
    }
    
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
        if userRole == "student" {
            collectionViewBottomConstraint.constant = 0
        } else if userRole == "teacher" {
            collectionViewBottomConstraint.constant = -500
        }
    }
    
    func uploadAllFiles() {
        for file in files {
            uploadFileToFirebase(file) { [weak self] result in
                switch result {
                case .success(let downloadURL):
                    self?.saveFileMetadataToFirestore(downloadURL: downloadURL, fileName: file.lastPathComponent)
                case .failure(let error):
                    print("File upload failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - 文件上傳到 Firebase
    func generateUniqueFileName(originalName: String) -> String {
        let uuid = UUID().uuidString
        return "\(uuid)_\(originalName)"
    }
    
    func uploadFileToFirebase(_ fileURL: URL, retryCount: Int = 3, completion: @escaping (Result<String, Error>) -> Void) {
        guard let currentUserID = UserSession.shared.currentUserID else {
            print("Error: Current user ID is nil.")
            completion(.failure(NSError(domain: "UserSession", code: -1, userInfo: [NSLocalizedDescriptionKey: "Current user ID is nil."])))
            return
        }
        
        let originalFileName = fileURL.lastPathComponent
        let uniqueFileName = generateUniqueFileName(originalName: originalFileName)
        let storageRef = storage.reference().child("files/\(uniqueFileName)")
        
        do {
            let fileData = try Data(contentsOf: fileURL)
            let metadata = StorageMetadata()
            metadata.contentType = "application/octet-stream"
            metadata.customMetadata = ["ownerId": currentUserID]
            
            print("Starting upload for file: \(uniqueFileName)")
            
            let uploadTask = storageRef.putData(fileData, metadata: metadata) { metadata, error in
                if let error = error {
                    if retryCount > 0 {
                        print("Upload failed, retrying... (\(retryCount) retries left)")
                        self.uploadFileToFirebase(fileURL, retryCount: retryCount - 1, completion: completion)
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
                            self.uploadFileToFirebase(fileURL, retryCount: retryCount - 1, completion: completion)
                        } else {
                            print("Download URL fetch failed with error: \(error.localizedDescription)")
                            completion(.failure(error))
                        }
                    } else if let url = url {
                        print("Upload successful. Download URL: \(url.absoluteString)")
                        completion(.success(url.absoluteString))
                    }
                }
            }
            
            // 監控上傳進度
            uploadTask.observe(.progress) { snapshot in
                if let progress = snapshot.progress {
                    let percentComplete = 100.0 * Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                    print("Upload is \(percentComplete)% complete.")
                }
            }
            
            uploadTask.observe(.failure) { snapshot in
                if let error = snapshot.error {
                    print("Upload failed during progress update: \(error.localizedDescription)")
                    // 可選：在這裡呼叫 completion(.failure(error)) 或實現其他錯誤處理
                }
            }
            
            // 保持對 uploadTask 的強引用
            self.currentUploadTask = uploadTask
        } catch {
            print("Error reading file data: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }
    
    @objc func uploadFiles() {
        print("Upload button clicked.")
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.item])
        documentPicker.delegate = self
        present(documentPicker, animated: true, completion: nil)
        
        print("Document picker presented.")
    }

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func saveFileMetadataToFirestore(downloadURL: String, fileName: String) {
        let currentUserID = UserSession.shared.currentUserID ?? "unknown_user"
        let fileData: [String: Any] = [
            "fileName": fileName,
            "downloadURL": downloadURL,
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
        var fileURL = files[indexPath.item]
        guard let oldFileName = fileURLs[fileURL] else { return }
        
        let newFileURL = fileURL.deletingLastPathComponent().appendingPathComponent(newName)
        
        files[indexPath.item] = newFileURL
        fileURLs[newFileURL] = newName
        fileURLs.removeValue(forKey: fileURL)
        
        updateFileMetadataInFirestore(for: fileURL, newFileName: newName)
        
        // 重新載入CollectionView
        collectionView.reloadItems(at: [indexPath])
    }
    
    func updateFileMetadataInFirestore(for fileURL: URL, newFileName: String) {
        // 查詢並更新 Firebase 中的文件名稱
        firestore.collection("files").whereField("downloadURL", isEqualTo: fileURL.absoluteString).getDocuments { [weak self] (snapshot, error) in
            if let error = error {
                print("Error finding file in Firestore: \(error.localizedDescription)")
                return
            }
            
            guard let document = snapshot?.documents.first else {
                print("File not found in Firestore.")
                return
            }
            
            // 更新文件名稱
            document.reference.updateData(["fileName": newFileName]) { error in
                if let error = error {
                    print("Error updating file name in Firestore: \(error.localizedDescription)")
                } else {
                    print("File name updated successfully in Firestore.")
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
    
    // MARK: - UIDocumentInteractionControllerDelegate
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
}

extension FilesVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return studentInfos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StudentCell", for: indexPath) as! StudentTableViewCell
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
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "fileCell", for: indexPath) as! FileCell
        if indexPath.item < files.count {
            let fileURL = files[indexPath.item]
            let isDownloading = fileDownloadStatus[fileURL] ?? false
            cell.configure(with: fileURL, isDownloading: isDownloading)
            cell.delegate = self // 設置委託
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item < files.count {
            let selectedFileURL = files[indexPath.item]
            
            if collectionView.allowsMultipleSelection {
                selectedFiles.append(selectedFileURL)
                if let cell = collectionView.cellForItem(at: indexPath) as? FileCell {
                    // Customize cell appearance for selected state if needed
                }
                print("選擇文件：\(selectedFileURL.lastPathComponent)")
                updateSendButtonState()
            } else {
                previewFile(at: selectedFileURL)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if indexPath.item < files.count {
            let deselectedFileURL = files[indexPath.item]
            
            if collectionView.allowsMultipleSelection {
                if let index = selectedFiles.firstIndex(of: deselectedFileURL) {
                    selectedFiles.remove(at: index)
                    print("取消選擇文件：\(deselectedFileURL.lastPathComponent)")
                }
                if let cell = collectionView.cellForItem(at: indexPath) as? FileCell {
                    // Customize cell appearance for deselected state if needed
                }
            }
            
            updateSendButtonState()
        }
    }
}

extension FilesVC: FileCellDelegate {
    func fileCellDidRequestDelete(_ cell: FileCell) {
            guard let indexPath = collectionView.indexPath(for: cell) else { return }
            let fileURL = files[indexPath.item]
            
            // 確認刪除操作
            let alert = UIAlertController(title: "刪除文件", message: "確定要刪除文件 \(fileURL.lastPathComponent) 嗎？", preferredStyle: .alert)
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
        let fileURL = files[indexPath.item]
        let alertController = UIAlertController(title: "編輯文件名稱", message: "請輸入新的文件名稱", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.text = fileURL.lastPathComponent
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
            let fileURL = files[indexPath.item]
            let fileName = fileURL.lastPathComponent
            
            // 1. 刪除 Firebase Storage 中的文件
            let storageRef = storage.reference(withPath: "files/\(fileName)")
            storageRef.delete { [weak self] error in
                if let error = error {
                    print("Error deleting file from Storage: \(error.localizedDescription)")
                    self?.showAlert(title: "刪除失敗", message: "無法刪除文件，請稍後再試。")
                    return
                }
                
                // 2. 刪除 Firestore 中的文件元數據
                self?.firestore.collection("files")
                    .whereField("downloadURL", isEqualTo: fileURL.absoluteString)
                    .getDocuments { snapshot, error in
                        if let error = error {
                            print("Error deleting file from Firestore: \(error.localizedDescription)")
                            return
                        }
                        
                        snapshot?.documents.first?.reference.delete(completion: { error in
                            if let error = error {
                                print("Error deleting file metadata from Firestore: \(error.localizedDescription)")
                            } else {
                                print("File and metadata successfully deleted.")
                                self?.files.remove(at: indexPath.item)
                                self?.collectionView.deleteItems(at: [indexPath])
                            }
                        })
                    }
            }
        }
}
