//
//  FilesVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/26.

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
    let userID = UserSession.shared.unwrappedUserID
    
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
        
        fetchStudentsNotes(forTeacherID: userID) { [weak self] notes in
            for (studentID, _) in notes {
                self?.fetchUser(from: Constants.studentsCollection, userID: studentID, as: Student.self)
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
        firestore.collection(Constants.teachersCollection).document(teacherID).getDocument { (snapshot, error) in
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
        startSendAnimation()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            for studentID in self.selectedStudentIDs {
                for fileItem in self.selectedFiles {
                    print("發送文件 \(fileItem.fileName) 給學生 \(studentID)")
                    
                    let fileName = fileItem.fileName
                    
                    self.firestore.collection(Constants.filesCollection)
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
        let cachedFiles = getCachedFiles()
        if !cachedFiles.isEmpty {
            self.files = cachedFiles
            DispatchQueue.main.async {
                self.collectionView.reloadData()
                self.restoreCollectionView()
            }
        } else {
            setCustomEmptyStateView()
        }
        
        if userRole == .student {
                setupFirestoreListener(for: userID)
            } else if userRole == .teacher {
                fetchTeacherFiles()
            }
    }
    
    func fetchTeacherFiles() {
        firestore.collection(Constants.filesCollection)
            .whereField("ownerID", isEqualTo: userID)
            .getDocuments { [weak self] (snapshot, error) in
                if let error = error {
                    print("Error fetching teacher files: \(error.localizedDescription)")
                    self?.setCustomEmptyStateView()
                    return
                }

                self?.handleFetchedFiles(snapshot)
            }
    }
    
    func setupFirestoreListener(for currentUserID: String) {
        guard userRole == .student else {
            return
        }
        
        let collectionPath = Constants.filesCollection
        let query = firestore.collection(collectionPath).whereField("authorizedStudents", arrayContains: currentUserID)
        
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
                let fileItem = FileItem(
                    localURL: fileURL,
                    remoteURL: fileURL,
                    downloadURL: "",
                    fileName: fileName,
                    storagePath: "files/\(fileName)"
                )
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
            DispatchQueue.main.async {
                self.collectionView.reloadData()
                self.setCustomEmptyStateView()
            }
            return
        }

        var remoteURLToFileItem: [URL: FileItem] = [:]
        for fileItem in self.files {
            remoteURLToFileItem[fileItem.remoteURL] = fileItem
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

            let storagePath = document.data()["storagePath"] as? String ?? "files/\(fileName)"

            if let existingFileItem = remoteURLToFileItem[remoteURL] {
                updatedFiles.append(existingFileItem)
                self.fileDownloadStatus[remoteURL] = false
            } else if let cachedURL = isFileCached(fileName: fileName) {
                let fileItem = FileItem(localURL: cachedURL, remoteURL: remoteURL, downloadURL: urlString, fileName: fileName, storagePath: storagePath)
                updatedFiles.append(fileItem)
                self.fileDownloadStatus[remoteURL] = false
                self.files.append(fileItem)
            } else {
                let fileItem = FileItem(localURL: nil, remoteURL: remoteURL, downloadURL: urlString, fileName: fileName, storagePath: storagePath)
                updatedFiles.append(fileItem)
                self.fileDownloadStatus[remoteURL] = true
                self.files.append(fileItem)

                self.downloadFile(from: remoteURL, withName: fileName)
            }
        }

        self.files = self.files.filter { fileItem in
            updatedFiles.contains(where: { $0.remoteURL == fileItem.remoteURL })
        }

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
    
    func uploadFileToFirebase(
        _ fileURL: URL,
        fileName: String,
        retryCount: Int = 3,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard prepareFileForUpload(fileURL, fileName: fileName) else {
            completion(.failure(NSError(domain: "FileAccess", code: -1, userInfo: [NSLocalizedDescriptionKey: "無法訪問"])))
            return
        }
        
        let storagePath = "files/\(fileName)"
        let storageRef = storage.reference().child(storagePath)
        let cachedFileURL = getCacheDirectory().appendingPathComponent(fileName)
        
        uploadData(to: storageRef, fileURL: cachedFileURL, fileName: fileName) { [weak self] result in
            switch result {
            case .success(let url):
                self?.handleSuccessfulUpload(url: url, fileName: fileName, storagePath: storagePath, cachedFileURL: cachedFileURL, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func prepareFileForUpload(_ fileURL: URL, fileName: String) -> Bool {
        guard fileURL.startAccessingSecurityScopedResource() else {
            print("無法訪問")
            return false
        }
        defer { fileURL.stopAccessingSecurityScopedResource() }
        
        let cachedFileURL = getCacheDirectory().appendingPathComponent(fileName)
        do {
            if FileManager.default.fileExists(atPath: cachedFileURL.path) {
                try FileManager.default.removeItem(at: cachedFileURL)
            }
            try FileManager.default.copyItem(at: fileURL, to: cachedFileURL)
            print("成功複製文件到緩存：\(cachedFileURL.path)")
        } catch {
            print("複製文件到緩存時發生錯誤：\(error.localizedDescription)")
            return false
        }
        return true
    }

    private func uploadData(to storageRef: StorageReference, fileURL: URL, fileName: String, completion: @escaping (Result<URL, Error>) -> Void) {
        showActivityIndicator()
        do {
            let fileData = try Data(contentsOf: fileURL)
            let metadata = StorageMetadata()
            metadata.contentType = "application/octet-stream"
            metadata.customMetadata = ["ownerId": userID]
            
            storageRef.putData(fileData, metadata: metadata) { [weak self] _, error in
                self?.hideActivityIndicator()
                if let error = error {
                    print("上傳失敗：\(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                storageRef.downloadURL { url, error in
                    if let error = error {
                        print("下載 URL 獲取失敗：\(error.localizedDescription)")
                        completion(.failure(error))
                    } else if let url = url {
                        completion(.success(url))
                    }
                }
            }
        } catch {
            hideActivityIndicator()
            print("讀取文件數據時發生錯誤：\(error.localizedDescription)")
            completion(.failure(error))
        }
    }

    private func handleSuccessfulUpload(
        url: URL, fileName: String,
        storagePath: String,
        cachedFileURL: URL,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        Task {
            do {
                try await saveFileMetadataToFirestore(downloadURL: url.absoluteString, storagePath: storagePath, fileName: fileName)
                DispatchQueue.main.async {
                                let newFileItem = FileItem(localURL: cachedFileURL, remoteURL: url, downloadURL: url.absoluteString, fileName: fileName, storagePath: storagePath)
                                self.files.append(newFileItem)
                                
                                if self.files.count == 1 {
                                    self.restoreCollectionView()
                                }
                                self.collectionView.reloadData()
                            }
                completion(.success(url.absoluteString))
            } catch {
                print("保存檔案時發生錯誤：\(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    func saveFileMetadataToFirestore(downloadURL: String, storagePath: String, fileName: String) async throws {
        let fileData: [String: Any] = [
            "fileName": fileName,
            "downloadURL": downloadURL,
            "storagePath": storagePath,
            "createdAt": Timestamp(),
            "ownerID": userID,
            "authorizedStudents": []
        ]
        
        try await firestore.collection(Constants.filesCollection).addDocument(data: fileData)
        print("檔案保存成功。")
    }
    
    func updateFileName(at indexPath: IndexPath, newName: String) {
        var fileItem = files[indexPath.item]
        
        let newFileName = newName
        
        if let localURL = fileItem.localURL {
            let newLocalURL = localURL.deletingLastPathComponent().appendingPathComponent(newFileName)
            
            do {
                try FileManager.default.moveItem(at: localURL, to: newLocalURL)
                
                fileItem = FileItem(
                    localURL: newLocalURL,
                    remoteURL: fileItem.remoteURL,
                    downloadURL: fileItem.downloadURL,
                    fileName: newFileName
                )
                files[indexPath.item] = fileItem
            } catch {
                print("Error renaming local file: \(error.localizedDescription)")
                showAlert(title: "重命名失敗", message: "無法重命名文件。")
                return
            }
        }
        
        updateFileMetadataInFirestore(for: fileItem, newFileName: newFileName)
        
        collectionView.reloadItems(at: [indexPath])
    }
    
    func updateFileMetadataInFirestore(for fileItem: FileItem, newFileName: String) {
        firestore.collection(Constants.filesCollection)
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
        guard let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("無法訪問")
        }
        let cacheDirectory = documentDirectory.appendingPathComponent("FileCache")
        
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
    
    func isTeacher() -> Bool {
        return userRole == .teacher
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
            print("Index out of range while deleting file.")
            return
        }
        
        let fileItem = files[indexPath.item]
        
        if userRole == .student {
            deleteLocalFile(fileItem, at: indexPath)
        } else if userRole == .teacher {
            deleteFileForTeacher(fileItem, at: indexPath)
        }
    }

    private func deleteLocalFile(_ fileItem: FileItem, at indexPath: IndexPath) {
        guard let localURL = fileItem.localURL else { return }
        
        do {
            try FileManager.default.removeItem(at: localURL)
            print("Local file deleted: \(localURL)")
        } catch {
            print("Error deleting local file: \(error.localizedDescription)")
        }
        
        DispatchQueue.main.async {
            self.files.remove(at: indexPath.item)
            self.collectionView.deleteItems(at: [indexPath])
            if self.files.isEmpty {
                self.setCustomEmptyStateView()
            }
        }
    }

    private func deleteFileForTeacher(_ fileItem: FileItem, at indexPath: IndexPath) {
        guard let storagePath = fileItem.storagePath, !storagePath.isEmpty else {
            print("Storage path is invalid or empty.")
            showAlert(title: "刪除失敗", message: "無法刪除文件，文件的路徑無效。")
            return
        }
        
        let storageRef = storage.reference().child(storagePath)
        
        storageRef.delete { [weak self] error in
            if let error = error {
                print("Error deleting file from Storage: \(error.localizedDescription)")
                self?.showAlert(title: "刪除失敗", message: "無法刪除文件，請稍後再試。")
                return
            }
            
            self?.deleteFileMetadata(fileItem, at: indexPath, storagePath: storagePath)
        }
    }


    private func deleteFileMetadata(_ fileItem: FileItem, at indexPath: IndexPath, storagePath: String) {
        firestore.collection(Constants.filesCollection)
            .whereField("storagePath", isEqualTo: storagePath)
            .getDocuments { [weak self] snapshot, error in
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
                        print("Error deleting file metadata: \(error.localizedDescription)")
                    } else {
                        print("Successfully deleted metadata for file: \(fileItem.fileName)")
                        self?.deleteLocalFileIfExists(fileItem, at: indexPath)
                    }
                }
            }
    }

    private func deleteLocalFileIfExists(_ fileItem: FileItem, at indexPath: IndexPath) {
        if let localURL = fileItem.localURL, FileManager.default.fileExists(atPath: localURL.path) {
            do {
                try FileManager.default.removeItem(at: localURL)
                print("Local file deleted successfully.")
            } catch {
                print("Error deleting local file: \(error.localizedDescription)")
            }
        }
        
        DispatchQueue.main.async {
            self.files.remove(at: indexPath.item)
            self.collectionView.deleteItems(at: [indexPath])
            
            if self.files.isEmpty {
                self.setCustomEmptyStateView()
            }
        }
    }
}

extension FilesVC: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedURL = urls.first else { return }
        let fileName = selectedURL.lastPathComponent
        
        guard selectedURL.startAccessingSecurityScopedResource() else {
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
                        case .success:
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
        
        firestore.collection(Constants.filesCollection)
            .whereField("fileName", isEqualTo: fileName)
            .whereField("ownerID", isEqualTo: userID)
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
    
    // MARK: - URLSessionDownloadDelegate
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
