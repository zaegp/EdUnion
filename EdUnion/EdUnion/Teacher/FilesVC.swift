//
//  FilesVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/26.
//

import UIKit
import FirebaseStorage
import FirebaseFirestore

class FilesVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIDocumentInteractionControllerDelegate {
    
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
    
    var userRole: String = UserDefaults.standard.string(forKey: "userRole") ?? "student"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupCollectionView()
        
        if userRole == "teacher" {
            setupStudentTableView()
            setupSendButton()
            setupLongPressGesture()
            setupMenu()
            uploadAllFiles()
        }
        
        fetchUserFiles()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tabBarController?.tabBar.isHidden = true
        if let tabBarController = self.tabBarController as? TabBarController {
            tabBarController.setCustomTabBarHidden(true, animated: true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let tabBarController = self.tabBarController as? TabBarController {
            tabBarController.setCustomTabBarHidden(false, animated: true)
        }
    }
    
    private func setupSendButton() {
        sendButton = UIButton(type: .system)
        sendButton.isHidden = true
        sendButton.setTitle("發送文件", for: .normal)
        sendButton.backgroundColor = .systemBlue
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
            studentTableView.heightAnchor.constraint(equalToConstant: 300)
        ])
        
        fetchStudentsNotes(forTeacherID: userID ?? "") { [weak self] notes in
            for (studentID, _) in notes {
                self?.fetchUser(from: "students", userID: studentID, as: Student.self)
            }
        }
    }
    
    @objc func selectMultipleFilesForSharing() {
        collectionView.allowsMultipleSelection = true
        sendButton.isHidden = false
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
        
        for studentID in selectedStudentIDs {
            for file in selectedFiles {
                print("發送文件 \(file.lastPathComponent) 給學生 \(studentID)")
                
                let fileName = file.lastPathComponent
                
                firestore.collection("files")
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
        
        selectedFiles.removeAll()
        selectedStudentIDs.removeAll()
        
        studentTableView.isHidden = true
        sendButton.isHidden = true
        
        collectionView.allowsMultipleSelection = false
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item < files.count {
            let selectedFileURL = files[indexPath.item]
            
            if collectionView.allowsMultipleSelection {
                selectedFiles.append(selectedFileURL)
                if let cell = collectionView.cellForItem(at: indexPath) as? FileCell {
                    cell.setSelected(true)
                }
                print("選擇文件：\(selectedFileURL.lastPathComponent)")
            } else {
                previewFile(at: selectedFileURL)
            }
            
            updateSendButtonState()
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
                    cell.setSelected(false)
                }
            }
            
            updateSendButtonState()
        }
    }
    
    func updateSendButtonState() {
        sendButton.isEnabled = !selectedFiles.isEmpty && !selectedStudentIDs.isEmpty
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
        
        // 使用 arrayContains 運算符來查找陣列中包含 currentUserID 的文件
        let query = userRole == "teacher" ?
                    firestore.collection(collectionPath).whereField(queryField, isEqualTo: currentUserID) :
                    firestore.collection(collectionPath).whereField(queryField, arrayContains: currentUserID)
        
        query.getDocuments { [weak self] snapshot, error in
            if let error = error {
                print("Error fetching user files: \(error)")
                return
            }
            
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
        
        for document in documents {
            guard let urlString = document.data()["downloadURL"] as? String,
                  let fileName = document.data()["fileName"] as? String,
                  let remoteURL = URL(string: urlString) else {
                continue
            }
            
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
        
        // 初始化 UICollectionView
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.allowsMultipleSelection = false
        collectionView.register(FileCell.self, forCellWithReuseIdentifier: "fileCell")
        collectionView.backgroundColor = .white // 設置背景色
        view.addSubview(collectionView)
        
        // 設置 CollectionView 的 AutoLayout
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leftAnchor.constraint(equalTo: view.leftAnchor),
            collectionView.rightAnchor.constraint(equalTo: view.rightAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -300)
        ])
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
    func uploadFileToFirebase(_ fileURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        let fileName = fileURL.lastPathComponent
        let storageRef = storage.reference().child("files/\(fileName)")
        
        let metadata = StorageMetadata()
        metadata.contentType = "application/octet-stream"
        
        storageRef.putFile(from: fileURL, metadata: metadata) { metadata, error in
            if let error = error {
                completion(.failure(error))
            } else {
                storageRef.downloadURL { url, error in
                    if let error = error {
                        completion(.failure(error))
                    } else if let url = url {
                        completion(.success(url.absoluteString))
                    }
                }
            }
        }
    }
    
    @objc func uploadFiles() {
        print("Upload button clicked.")
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.item])
        documentPicker.delegate = self
        present(documentPicker, animated: true, completion: nil)
        
        print("Document picker presented.")
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
                print("Error saving file metadata: \(error)")
            } else {
                print("File metadata saved successfully.")
            }
        }
    }
    
    // MARK: - UICollectionView DataSource & Delegate Methods
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return files.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "fileCell", for: indexPath) as! FileCell
        if indexPath.item < files.count {
            let fileURL = files[indexPath.item]
            let isDownloading = fileDownloadStatus[fileURL] ?? false
            cell.configure(with: fileURL, isDownloading: isDownloading)
        }
        return cell
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
    
    func updateFileName(at indexPath: IndexPath, newName: String) {
        var fileURL = files[indexPath.item]
        
        let newFileURL = fileURL.deletingLastPathComponent().appendingPathComponent(newName)
        
        files[indexPath.item] = newFileURL
        
        updateFileMetadataInFirestore(for: fileURL, newFileName: newName)
        
        // 重新載入CollectionView
        collectionView.reloadItems(at: [indexPath])
    }
    
    func updateFileMetadataInFirestore(for fileURL: URL, newFileName: String) {
        // 查詢並更新 Firebase 中的文件名稱
        firestore.collection("files").whereField("fileName", isEqualTo: fileURL.lastPathComponent).getDocuments { [weak self] (snapshot, error) in
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
        let student = studentInfos[indexPath.row]
        cell.configure(with: student)
        
        // 設置選擇狀態
        cell.accessoryType = selectedStudentIDs.contains(student.id) ? .checkmark : .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let student = studentInfos[indexPath.row]
        
        // 添加或移除選擇的學生
        if selectedStudentIDs.contains(student.id) {
            selectedStudentIDs.remove(student.id)
        } else {
            selectedStudentIDs.insert(student.id)
        }
        
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}

class StudentTableViewCell: UITableViewCell {
    let nameLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with student: Student) {
        nameLabel.text = student.fullName
    }
}

// MARK: - UIDocumentPickerDelegate
extension FilesVC: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        print("Document picker did pick documents: \(urls)")
        
        if urls.isEmpty {
            print("Error: No files were selected.")
            return
        }
        
        let selectedURL = urls[0] 
        let fileName = selectedURL.lastPathComponent
        
        checkIfFileExists(fileName: fileName) { [weak self] exists in
            if exists {
                print("Error: A file with the same name already exists.")
                self?.showAlert(message: "已有同名文件，請重新選擇")
            } else {
                self?.files.append(selectedURL)
                self?.collectionView.reloadData()
                self?.uploadFileToFirebase(selectedURL) { result in
                    switch result {
                    case .success(let downloadURL):
                        self?.saveFileMetadataToFirestore(downloadURL: downloadURL, fileName: fileName)
                    case .failure(let error):
                        print("File upload failed: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    func checkIfFileExists(fileName: String, completion: @escaping (Bool) -> Void) {
        let currentUserID = UserSession.shared.currentUserID ?? "unknown_user"
        firestore.collection("files")
            .whereField("ownerID", isEqualTo: currentUserID)
            .whereField("fileName", isEqualTo: fileName)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error checking file existence: \(error)")
                    completion(false)
                } else if let snapshot = snapshot, !snapshot.isEmpty {
                    completion(true)
                } else {
                    completion(false)
                }
            }
    }
    
    func showAlert(message: String) {
        let alert = UIAlertController(title: "已有同名文件", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("Document picker was cancelled")
    }
}
