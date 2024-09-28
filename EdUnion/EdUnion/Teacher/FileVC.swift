////
////  FileVC.swift
////  EdUnion
////
////  Created by Rowan Su on 2024/9/29.
////
//
//import UIKit
//import FirebaseStorage
//import FirebaseFirestore
//
//
//
//class AvatarCell: UICollectionViewCell {
//    let imageView = UIImageView()
//    let nameLabel = UILabel()
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        
//        // 設置頭貼
//        imageView.contentMode = .scaleAspectFill
//        imageView.layer.cornerRadius = 25 // 圓形效果
//        imageView.clipsToBounds = true
//        imageView.translatesAutoresizingMaskIntoConstraints = false
//        contentView.addSubview(imageView)
//        
//        // 設置名字
//        nameLabel.font = UIFont.systemFont(ofSize: 12)
//        nameLabel.textAlignment = .center
//        nameLabel.translatesAutoresizingMaskIntoConstraints = false
//        contentView.addSubview(nameLabel)
//        
//        // 設置 AutoLayout
//        NSLayoutConstraint.activate([
//            imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
//            imageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
//            imageView.widthAnchor.constraint(equalToConstant: 50),
//            imageView.heightAnchor.constraint(equalToConstant: 50),
//            
//            nameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 5),
//            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5),
//            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5)
//        ])
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    func configure(with image: UIImage, name: String) {
//        imageView.image = image
//        nameLabel.text = name
//    }
//}
//
//
//class FileVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIDocumentInteractionControllerDelegate, UIDocumentPickerDelegate {
//    
//    var collectionView: UICollectionView!
//    var avatarCollectionView: UICollectionView!
//    var selectedFiles: [URL] = []
//    var files: [URL] = []
//    var documentInteractionController: UIDocumentInteractionController?
//    
//    let storage = Storage.storage()
//    let firestore = Firestore.firestore()
//    let userID = UserSession.shared.currentUserID
//    var studentInfos: [Student] = []
//    var selectedStudentIDs: Set<String> = []
//    var shareButton: UIButton!
//    var sendButton: UIButton!
//    var avatars: [(image: UIImage, name: String, studentID: String)] = []
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        setupCollectionView()
//        setupAvatarCollectionView()
//        setupSendButton()
//        setupLongPressGesture()
//        
//        let menuButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), style: .plain, target: nil, action: nil)
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
//        
//        shareButton = UIButton(type: .system)
//        shareButton.setTitle("分享", for: .normal)
//        shareButton.backgroundColor = .systemBlue
//        shareButton.tintColor = .white
//        shareButton.layer.cornerRadius = 10
//        shareButton.isHidden = true
//        shareButton.addTarget(self, action: #selector(shareSelectedFiles), for: .touchUpInside)
//        
//        view.addSubview(shareButton)
//        shareButton.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            shareButton.heightAnchor.constraint(equalToConstant: 50),
//            shareButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
//            shareButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
//            shareButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
//        ])
//        
//        uploadAllFiles()
//        fetchUserFiles()
//    }
//    
//    private func setupSendButton() {
//        sendButton = UIButton(type: .system)
//        sendButton.setTitle("發送文件", for: .normal)
//        sendButton.backgroundColor = .systemBlue
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
//    private func setupAvatarCollectionView() {
//        let layout = UICollectionViewFlowLayout()
//        layout.scrollDirection = .horizontal
//        layout.itemSize = CGSize(width: 60, height: 80)
//        layout.minimumInteritemSpacing = 10
//        layout.minimumLineSpacing = 10
//        
//        avatarCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
//        avatarCollectionView.delegate = self
//        avatarCollectionView.dataSource = self
//        avatarCollectionView.register(AvatarCell.self, forCellWithReuseIdentifier: "AvatarCell")
//        avatarCollectionView.backgroundColor = .white
//        
//        view.addSubview(avatarCollectionView)
//        avatarCollectionView.translatesAutoresizingMaskIntoConstraints = false
//        
//        NSLayoutConstraint.activate([
//            avatarCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
//            avatarCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
//            avatarCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
//            avatarCollectionView.heightAnchor.constraint(equalToConstant: 100)
//        ])
//    }
//    
//    func updateFileName(at indexPath: IndexPath, newName: String) {
//            // 獲取原始文件URL
//            var fileURL = files[indexPath.item]
//    
//            // 更新本地URL（僅用於顯示，並未更改實際文件）
//            let newFileURL = fileURL.deletingLastPathComponent().appendingPathComponent(newName)
//    
//            files[indexPath.item] = newFileURL
//    
//            // 更新 Firebase 上的文件名稱
//            updateFileMetadataInFirestore(for: fileURL, newFileName: newName)
//    
//            // 重新載入CollectionView
//            collectionView.reloadItems(at: [indexPath])
//        }
//    
//        func updateFileMetadataInFirestore(for fileURL: URL, newFileName: String) {
//            // 查詢並更新 Firebase 中的文件名稱
//            firestore.collection("files").whereField("fileName", isEqualTo: fileURL.lastPathComponent).getDocuments { [weak self] (snapshot, error) in
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
//                // 更新文件名稱
//                document.reference.updateData(["fileName": newFileName]) { error in
//                    if let error = error {
//                        print("Error updating file name in Firestore: \(error.localizedDescription)")
//                    } else {
//                        print("File name updated successfully in Firestore.")
//                    }
//                }
//            }
//        }
//    
//    func fetchUserFiles() {
//            guard let currentUserID = UserSession.shared.currentUserID else {
//                print("Error: Current user ID is nil.")
//                return
//            }
//    
//            firestore.collection("files")
//                .whereField("ownerID", isEqualTo: currentUserID)
//                .getDocuments { [weak self] snapshot, error in
//                    if let error = error {
//                        print("Error fetching user files: \(error)")
//                        return
//                    }
//    
//                    guard let documents = snapshot?.documents else {
//                        print("No files found for current user.")
//                        return
//                    }
//    
//                    self?.files.removeAll()
//    
//                    for document in documents {
//                        guard let urlString = document.data()["downloadURL"] as? String,
//                              let fileName = document.data()["fileName"] as? String,
//                              let url = URL(string: urlString) else {
//                            continue
//                        }
//    
//                        self?.downloadFile(from: url, withName: fileName)
//                    }
//                }
//        }
//    
//    func editFileName(at indexPath: IndexPath) {
//            let fileURL = files[indexPath.item]
//            let alertController = UIAlertController(title: "編輯文件名稱", message: "請輸入新的文件名稱", preferredStyle: .alert)
//            alertController.addTextField { textField in
//                textField.text = fileURL.lastPathComponent
//            }
//    
//            let confirmAction = UIAlertAction(title: "確定", style: .default) { [weak self] _ in
//                if let newFileName = alertController.textFields?.first?.text, !newFileName.isEmpty {
//                    self?.updateFileName(at: indexPath, newName: newFileName)
//                }
//            }
//    
//            let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
//    
//            alertController.addAction(confirmAction)
//            alertController.addAction(cancelAction)
//    
//            present(alertController, animated: true, completion: nil)
//        }
//    
//    func setupLongPressGesture() {
//            let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
//            collectionView.addGestureRecognizer(longPressGesture)
//        }
//    
//    func saveFileMetadataToFirestore(downloadURL: String, fileName: String) {
//            let currentUserID = UserSession.shared.currentUserID ?? "unknown_user"
//            let fileData: [String: Any] = [
//                "fileName": fileName,
//                "downloadURL": downloadURL,
//                "createdAt": Timestamp(),
//                "ownerID": currentUserID
//            ]
//    
//            firestore.collection("files").addDocument(data: fileData) { error in
//                if let error = error {
//                    print("Error saving file metadata: \(error)")
//                } else {
//                    print("File metadata saved successfully.")
//                }
//            }
//        }
//
//    @objc func selectMultipleFilesForSharing() {
//        collectionView.allowsMultipleSelection = true
//        shareButton.isHidden = false
//    }
//    
//    @objc func handleLongPress(gesture: UILongPressGestureRecognizer) {
//            let point = gesture.location(in: collectionView)
//            if let indexPath = collectionView.indexPathForItem(at: point) {
//                editFileName(at: indexPath)
//            }
//        }
//    
//    @objc func shareSelectedFiles() {
//        if selectedFiles.isEmpty {
//            print("沒有選擇任何文件")
//            return
//        }
//        
//        fetchStudentsNotes(forTeacherID: userID ?? "") { [weak self] notes in
//            for (studentID, _) in notes {
//                self?.fetchUser(from: "students", userID: studentID, as: Student.self)
//            }
//        }
//        
//        print("分享文件：\(selectedFiles)")
//        
//        collectionView.allowsMultipleSelection = true
//        shareButton.isHidden = true
//        collectionView.reloadData()
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
//    @objc func uploadFiles() {
//            print("Upload button clicked.")
//            let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.item])
//            documentPicker.delegate = self
//            present(documentPicker, animated: true, completion: nil)
//    
//            print("Document picker presented.")
//        }
//    
//    func uploadFileToFirebase(_ fileURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
//            let fileName = fileURL.lastPathComponent
//            let storageRef = storage.reference().child("files/\(fileName)")
//    
//            let metadata = StorageMetadata()
//            metadata.contentType = "application/octet-stream"
//    
//            storageRef.putFile(from: fileURL, metadata: metadata) { metadata, error in
//                if let error = error {
//                    completion(.failure(error))
//                } else {
//                    storageRef.downloadURL { url, error in
//                        if let error = error {
//                            completion(.failure(error))
//                        } else if let url = url {
//                            completion(.success(url.absoluteString))
//                        }
//                    }
//                }
//            }
//        }
//
//    func fetchUser<T: UserProtocol & Decodable>(from collection: String, userID: String, as type: T.Type) {
//        UserFirebaseService.shared.fetchUser(from: collection, by: userID, as: type) { [weak self] result in
//            switch result {
//            case .success(let user):
//                if let student = user as? Student {
//                    self?.studentInfos.append(student)
//                    let image = UIImage(systemName: "person.circle")!
//                    let name = student.fullName.isEmpty ? "Unknown Student" : student.fullName
//                    self?.avatars.append((image: image, name: name, studentID: student.id))
//                }
//                DispatchQueue.main.async {
//                    self?.avatarCollectionView.reloadData()
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
//        for studentID in selectedStudentIDs {
//            for file in selectedFiles {
//                print("發送文件 \(file.lastPathComponent) 給學生 \(studentID)")
//                // 在這裡實現實際的發送文件到學生的邏輯
//            }
//        }
//    }
//    
//    func downloadFile(from url: URL, withName fileName: String) {
//            let task = URLSession.shared.downloadTask(with: url) { [weak self] (tempLocalUrl, response, error) in
//                if let error = error {
//                    print("Error downloading file: \(error.localizedDescription)")
//                    return
//                }
//    
//                guard let tempLocalUrl = tempLocalUrl else {
//                    print("Error: Temporary local URL is nil.")
//                    return
//                }
//    
//                let fileManager = FileManager.default
//                let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
//                let localUrl = documentsDirectory.appendingPathComponent(fileName)
//    
//                do {
//                    if fileManager.fileExists(atPath: localUrl.path) {
//                        try fileManager.removeItem(at: localUrl)
//                    }
//                    try fileManager.moveItem(at: tempLocalUrl, to: localUrl)
//    
//                    DispatchQueue.main.async {
//                        self?.files.append(localUrl)
//                        self?.collectionView.reloadData()
//                    }
//                } catch {
//                    print("Error moving file: \(error.localizedDescription)")
//                }
//            }
//            task.resume()
//        }
//    
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        if collectionView == self.avatarCollectionView {
//            let studentID = avatars[indexPath.item].studentID
//            if selectedStudentIDs.contains(studentID) {
//                selectedStudentIDs.remove(studentID)
//            } else {
//                selectedStudentIDs.insert(studentID)
//            }
//            
//            collectionView.reloadItems(at: [indexPath])
//        } else if indexPath.item < files.count {
//            let selectedFileURL = files[indexPath.item]
//            selectedFiles.append(selectedFileURL)
//            print("選擇文件：\(selectedFileURL.lastPathComponent)")
//            
//            if let cell = collectionView.cellForItem(at: indexPath) as? FileCell {
//                cell.setSelected(true)
//            }
//        }
//    }
//
//    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
//        if collectionView == self.avatarCollectionView {
//            let studentID = avatars[indexPath.item].studentID
//            selectedStudentIDs.remove(studentID)
//            collectionView.reloadItems(at: [indexPath])
//        } else if indexPath.item < files.count {
//            let deselectedFileURL = files[indexPath.item]
//            if let index = selectedFiles.firstIndex(of: deselectedFileURL) {
//                selectedFiles.remove(at: index)
//                print("取消選擇文件：\(deselectedFileURL.lastPathComponent)")
//            }
//            
//            if let cell = collectionView.cellForItem(at: indexPath) as? FileCell {
//                cell.setSelected(false)
//            }
//        }
//    }
//
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        if collectionView == avatarCollectionView {
//            return avatars.count
//        } else {
//            return files.count
//        }
//    }
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
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        if collectionView == avatarCollectionView {
//            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AvatarCell", for: indexPath) as! AvatarCell
//            let avatar = avatars[indexPath.item]
//            cell.configure(with: avatar.image, name: avatar.name)
//            
//            // 設置選中狀態的視覺效果
//            cell.layer.borderWidth = selectedStudentIDs.contains(avatar.studentID) ? 2 : 0
//            cell.layer.borderColor = UIColor.systemBlue.cgColor
//            return cell
//        } else {
//            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "fileCell", for: indexPath) as! FileCell
//            let fileURL = files[indexPath.item]
//            cell.configure(with: fileURL)
//            
//            // 更新選中狀態的視覺效果
//            cell.setSelected(selectedFiles.contains(fileURL))
//            return cell
//        }
//    }
//    
//    private func setupCollectionView() {
//        let layout = UICollectionViewFlowLayout()
//        let numberOfItemsPerRow: CGFloat = 3
//        let spacing: CGFloat = 10
//        let totalSpacing = (2 * spacing) + ((numberOfItemsPerRow - 1) * spacing)
//        let itemWidth = (view.bounds.width - totalSpacing) / numberOfItemsPerRow
//        layout.itemSize = CGSize(width: itemWidth, height: itemWidth + 20)
//        layout.sectionInset = UIEdgeInsets(top: spacing, left: spacing, bottom: spacing, right: spacing)
//        layout.minimumInteritemSpacing = spacing
//        layout.minimumLineSpacing = spacing
//        
//        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
//        collectionView.delegate = self
//        collectionView.dataSource = self
//        collectionView.allowsMultipleSelection = true
//        collectionView.register(FileCell.self, forCellWithReuseIdentifier: "fileCell")
//        collectionView.backgroundColor = .white
//        view.addSubview(collectionView)
//        
//        collectionView.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            collectionView.topAnchor.constraint(equalTo: avatarCollectionView.bottomAnchor, constant: 16),
//            collectionView.leftAnchor.constraint(equalTo: view.leftAnchor),
//            collectionView.rightAnchor.constraint(equalTo: view.rightAnchor),
//            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
//        ])
//    }
//}
//
