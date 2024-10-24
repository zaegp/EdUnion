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
                activityIndicator.hidesWhenStopped = true 
                self.view.addSubview(activityIndicator)
    }
    
    func showActivityIndicator() {
            DispatchQueue.main.async {
                self.activityIndicator.startAnimating()
            }
        }
        
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
        let planeImageView = UIImageView(image: UIImage(systemName: "paperplane.fill"))
        planeImageView.tintColor = .mainOrange
        planeImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(planeImageView)
        
        NSLayoutConstraint.activate([
            planeImageView.centerXAnchor.constraint(equalTo: sendButton.centerXAnchor),
            planeImageView.centerYAnchor.constraint(equalTo: sendButton.centerYAnchor),
            planeImageView.widthAnchor.constraint(equalToConstant: 30),
            planeImageView.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        UIView.animate(withDuration: 1.0, animations: {
            planeImageView.transform = CGAffineTransform(translationX: self.view.frame.width, y: -self.view.frame.height / 2)
            planeImageView.alpha = 0
        }, completion: { _ in
            planeImageView.removeFromSuperview()
            
            self.showCheckmarkAnimation()
        })
    }

    func showCheckmarkAnimation() {
        let checkmarkImageView = UIImageView(image: UIImage(systemName: "checkmark"))
        checkmarkImageView.tintColor = .mainOrange
        
        checkmarkImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(checkmarkImageView)
        
        NSLayoutConstraint.activate([
            checkmarkImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            checkmarkImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 100),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 100)
        ])
        
        checkmarkImageView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        checkmarkImageView.alpha = 0
        UIView.animate(withDuration: 0.5, animations: {
            checkmarkImageView.transform = CGAffineTransform.identity
            checkmarkImageView.alpha = 1
        }, completion: { _ in
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
        sendButton.backgroundColor = canSend ? .mainOrange : .gray
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
       
       func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
           return previewItem == nil ? 0 : 1
       }
       
       func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
           return previewItem!
       }
    
    func fetchUserFiles() {
        guard let currentUserID = UserSession.shared.currentUserID else {
            print("Error: Current user ID is nil.")
            setCustomEmptyStateView()
            return
        }
        
        let cachedFiles = getCachedFiles()
        if !cachedFiles.isEmpty {
            self.files = cachedFiles
            DispatchQueue.main.async {
                self.collectionView.reloadData()
                self.restoreCollectionView()
            }
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
                self?.setCustomEmptyStateView()
                return
            }

            guard let snapshot = snapshot else {
                print("No snapshot received.")
                self?.files.removeAll()
                self?.collectionView.reloadData()
                self?.setCustomEmptyStateView()
                return
            }

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
            setCustomEmptyStateView()
            return
        }

        var updatedFiles: [FileItem] = []
        self.fileDownloadStatus.removeAll()
        self.fileURLs.removeAll()

        for document in documents {
            guard let urlString = document.data()["downloadURL"] as? String,
                  let fileName = document.data()["fileName"] as? String,
                  let remoteURL = URL(string: urlString) else {
                continue
            }

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

                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }

                self.downloadFile(from: remoteURL, withName: fileName)
            }
        }

        self.files = updatedFiles

        DispatchQueue.main.async {
            self.collectionView.reloadData()
            if self.files.isEmpty {
                self.setCustomEmptyStateView()
            } else {
                self.restoreCollectionView()
            }
        }
    }
    
    func setupCollectionView() {
        
        let layout = UICollectionViewFlowLayout()
        
        let numberOfItemsPerRow: CGFloat = 3
        let spacing: CGFloat = 10
        
        let totalSpacing = (2 * spacing) + ((numberOfItemsPerRow - 1) * spacing)
        let itemWidth = (view.bounds.width - totalSpacing) / numberOfItemsPerRow
        
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth + 20)
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
        
        guard fileURL.startAccessingSecurityScopedResource() else {
            print("無法訪問安全範圍資源")
            completion(.failure(NSError(domain: "FileAccess", code: -1, userInfo: [NSLocalizedDescriptionKey: "無法訪問安全範圍資源"])))
            return
        }
        defer {
            fileURL.stopAccessingSecurityScopedResource()
        }
        
        // Step 1: Copy the file to the app's cache directory
        let cacheDirectory = getCacheDirectory()
        let cachedFileURL = cacheDirectory.appendingPathComponent(fileName)
        do {
            if FileManager.default.fileExists(atPath: cachedFileURL.path) {
                try FileManager.default.removeItem(at: cachedFileURL)
            }
            try FileManager.default.copyItem(at: fileURL, to: cachedFileURL)
            print("成功複製文件到緩存：\(cachedFileURL.path)")
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
            
            let uploadTask = storageRef.putData(fileData, metadata: metadata) { metadata, error in
                self.hideActivityIndicator()
                if let error = error {
                    print("Upload failed with error: \(error.localizedDescription)")
                    print("Error details: \(error)")
                    completion(.failure(error))
                    return
                }
                
                print("Upload completed, fetching download URL.")
                
                storageRef.downloadURL { url, error in
                    if let error = error {
                        print("Download URL fetch failed with error: \(error.localizedDescription)")
                        completion(.failure(error))
                    } else if let url = url {
                        print("Upload successful. Download URL: \(url.absoluteString)")
                        
                        // 保存文件元数据到 Firestore
                        self.saveFileMetadataToFirestore(downloadURL: url.absoluteString, storagePath: storagePath, fileName: fileName)
                        
                        // Step 2: 创建新的 FileItem 并添加到 files 数组
                        let newFileItem = FileItem(localURL: cachedFileURL, remoteURL: url, downloadURL: url.absoluteString, fileName: fileName, storagePath: storagePath)
                        DispatchQueue.main.async {
                            self.files.append(newFileItem)
                            self.collectionView.reloadData()
                        }
                        
                        completion(.success(url.absoluteString))
                    }
                }
            }
            
            uploadTask.observe(.progress) { snapshot in
                if let progress = snapshot.progress {
                    let percentComplete = 100.0 * Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                    DispatchQueue.main.async {
                    }
                }
            }
            
            uploadTask.observe(.failure) { snapshot in
                self.hideActivityIndicator()
                if let error = snapshot.error {
                    print("Upload failed during progress update: \(error.localizedDescription)")
                    print("Error details: \(error)")
                    completion(.failure(error))
                }
            }
            
            self.currentUploadTask = uploadTask
        } catch {
            print("Error reading file data: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }
    
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
        
        let newFileName = newName
        
        if let localURL = fileItem.localURL {
            let newLocalURL = localURL.deletingLastPathComponent().appendingPathComponent(newFileName)
            
            do {
                try FileManager.default.moveItem(at: localURL, to: newLocalURL)
                
                fileItem = FileItem(localURL: newLocalURL, remoteURL: fileItem.remoteURL, downloadURL: fileItem.downloadURL, fileName: newFileName)
                files[indexPath.item] = fileItem
            } catch {
                print("Error renaming local file: \(error.localizedDescription)")
                showAlert(title: "重命名失敗", message: "無法重命名本地文件。")
                return
            }
        }
        
        updateFileMetadataInFirestore(for: fileItem, newFileName: newFileName)
        
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
        
        if userRole == .student {
            if let localURL = fileItem.localURL {
                do {
                    try FileManager.default.removeItem(at: localURL)
                    print("本地文件成功刪除：\(localURL)")
                } catch {
                    print("刪除本地文件時出錯：\(error.localizedDescription)")
                }
            }
            
            DispatchQueue.main.async {
                self.files.remove(at: indexPath.item)
                self.collectionView.deleteItems(at: [indexPath])
                if self.files.isEmpty {
                    self.setCustomEmptyStateView()
                }
            }
            
        } else if userRole == .teacher {
            guard let storagePath = fileItem.storagePath, !storagePath.isEmpty else {
                print("Error: storagePath is nil or empty.")
                showAlert(title: "刪除失敗", message: "無法刪除文件，文件的存儲路徑無效。")
                return
            }

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

                                do {
                                    if let localURL = fileItem.localURL, FileManager.default.fileExists(atPath: localURL.path) {
                                        try FileManager.default.removeItem(at: localURL)
                                        print("Local file deleted successfully.")
                                    }
                                } catch {
                                    print("Error deleting local file: \(error.localizedDescription)")
                                }

                                DispatchQueue.main.async {
                                    guard let self = self else { return }
                                    self.files.remove(at: indexPath.item)
                                    self.collectionView.deleteItems(at: [indexPath])
                                    
                                    if self.files.isEmpty {
                                        self.setCustomEmptyStateView()
                                    }
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

        guard selectedURL.startAccessingSecurityScopedResource() else {
            print("无法访问安全范围资源")
            return
        }

        defer {
            selectedURL.stopAccessingSecurityScopedResource()
        }

        checkIfFileExists(fileName: fileName) { [weak self] exists in
            if exists {
                DispatchQueue.main.async {
                    self?.showAlert(title: "文件已存在", message: "已存在同名文件，請選擇其他文件或更改文件名稱。")
                }
            } else {
                self?.uploadFileToFirebase(selectedURL, fileName: fileName) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(_):
                            self?.showAlert(title: "上傳成功", message: "")
                        case .failure(let error):
                            print("文件上傳失敗: \(error.localizedDescription)")
                            self?.showAlert(title: "上傳失敗", message: "無法上傳文件，請稍後再試。")
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
                    completion(true)
                } else {
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

    func updateDownloadProgress(for url: URL, progress: Double) {
        if let index = files.firstIndex(where: { $0.remoteURL == url }) {
            let indexPath = IndexPath(item: index, section: 0)

            if let cell = collectionView.cellForItem(at: indexPath) as? FileCell {
                cell.updateProgress(Float(progress))
            }
        }
    }
}

