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
    
    let storage = Storage.storage()
    let firestore = Firestore.firestore()
    
    var shareButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCollectionView()
        setupLongPressGesture()
        
        let menuButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), style: .plain, target: nil, action: nil)
        navigationItem.rightBarButtonItem = menuButton
        
        // 建立 UIMenu
        let menu = UIMenu(title: "", children: [
            UIAction(title: "上傳檔案", image: UIImage(systemName: "doc.badge.plus")) { [weak self] _ in
                self?.uploadFiles()
            },
            UIAction(title: "選取多個文件分享", image: UIImage(systemName: "square.and.arrow.up")) { [weak self] _ in
                self?.selectMultipleFilesForSharing()
            }
        ])
        
        // 將 menu 設置給 navigationItem 的 barButtonItem
        menuButton.menu = menu
        menuButton.primaryAction = nil
        
        shareButton = UIBarButtonItem(title: "分享", style: .plain, target: self, action: #selector(shareSelectedFiles))
        
        uploadAllFiles()
        fetchUserFiles()
    }

    @objc func selectMultipleFilesForSharing() {
            collectionView.allowsMultipleSelection = true
            navigationItem.leftBarButtonItem = shareButton // 顯示分享按鈕
        }
        
        @objc func shareSelectedFiles() {
            if selectedFiles.isEmpty {
                print("沒有選擇任何文件")
                return
            }
            
            // 在這裡實作分享至聊天室的邏輯
            print("分享文件：\(selectedFiles)")
            // 這裡可以呼叫您分享至聊天室的功能，並將 `selectedFiles` 作為參數傳入
            
            // 完成後，退出多選模式
            collectionView.allowsMultipleSelection = false
            selectedFiles.removeAll()
            navigationItem.leftBarButtonItem = nil // 隱藏分享按鈕
            collectionView.reloadData()
        }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            if indexPath.item < files.count {
                let selectedFileURL = files[indexPath.item]
                selectedFiles.append(selectedFileURL)
                print("選擇文件：\(selectedFileURL.lastPathComponent)")
            }
        }
        
        func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
            if indexPath.item < files.count {
                let deselectedFileURL = files[indexPath.item]
                if let index = selectedFiles.firstIndex(of: deselectedFileURL) {
                    selectedFiles.remove(at: index)
                    print("取消選擇文件：\(deselectedFileURL.lastPathComponent)")
                }
            }
        }
    
    func fetchUserFiles() {
        guard let currentUserID = UserSession.shared.currentUserID else {
            print("Error: Current user ID is nil.")
            return
        }
        
        firestore.collection("files")
            .whereField("ownerID", isEqualTo: currentUserID)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching user files: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No files found for current user.")
                    return
                }
                
                self?.files.removeAll()
                
                for document in documents {
                    guard let urlString = document.data()["downloadURL"] as? String,
                          let fileName = document.data()["fileName"] as? String,
                          let url = URL(string: urlString) else {
                        continue
                    }
                    
                    self?.downloadFile(from: url, withName: fileName)
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
            
            let fileManager = FileManager.default
            let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let localUrl = documentsDirectory.appendingPathComponent(fileName)
            
            do {
                // 移動文件到文檔目錄
                if fileManager.fileExists(atPath: localUrl.path) {
                    try fileManager.removeItem(at: localUrl)
                }
                try fileManager.moveItem(at: tempLocalUrl, to: localUrl)
                
                // 添加文件到 files 陣列
                DispatchQueue.main.async {
                    self?.files.append(localUrl)
                    self?.collectionView.reloadData()
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
        collectionView.allowsMultipleSelection = true
        collectionView.register(FileCell.self, forCellWithReuseIdentifier: "fileCell")
        collectionView.backgroundColor = .white // 設置背景色
        view.addSubview(collectionView)
        
        // 設置 CollectionView 的 AutoLayout
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leftAnchor.constraint(equalTo: view.leftAnchor),
            collectionView.rightAnchor.constraint(equalTo: view.rightAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
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
            "ownerID": currentUserID
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
            cell.configure(with: fileURL)
        }
        return cell
    }
    
    //    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    //        if indexPath.item < files.count {
    //            let selectedFile = files[indexPath.item]
    //            selectedFiles.append(selectedFile)
    //            print("File selected: \(selectedFile.lastPathComponent)")
    //
    //            // 開始上傳文件到 Firebase
    //            uploadFileToFirebase(selectedFile) { [weak self] result in
    //                switch result {
    //                case .success(let downloadURL):
    //                    self?.saveFileMetadataToFirestore(downloadURL: downloadURL, fileName: selectedFile.lastPathComponent)
    //                case .failure(let error):
    //                    print("File upload failed: \(error.localizedDescription)")
    //                }
    //            }
    //        } else {
    //            print("Error: Selected index out of bounds.")
    //        }
    //    }
    
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        if indexPath.item < files.count {
//            let selectedFileURL = files[indexPath.item]
//            previewFile(at: selectedFileURL)
//        }
//    }
    
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
    
    // 顯示彈出視窗以編輯文件名稱
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
        // 獲取原始文件URL
        var fileURL = files[indexPath.item]
        
        // 更新本地URL（僅用於顯示，並未更改實際文件）
        let newFileURL = fileURL.deletingLastPathComponent().appendingPathComponent(newName)
        
        files[indexPath.item] = newFileURL
        
        // 更新 Firebase 上的文件名稱
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
    
    func previewFile(at url: URL) {
        documentInteractionController = UIDocumentInteractionController(url: url)
        documentInteractionController?.delegate = self
        documentInteractionController?.presentPreview(animated: true)
    }
    
    // MARK: - UIDocumentInteractionControllerDelegate
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
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
        
        let selectedURL = urls[0] // 這裡假設一次只選取一個文件
        let fileName = selectedURL.lastPathComponent
        
        // 檢查文件名稱是否已經存在
        checkIfFileExists(fileName: fileName) { [weak self] exists in
            if exists {
                print("Error: A file with the same name already exists.")
                // 可以彈出警告通知使用者文件名稱重複
                self?.showAlert(message: "A file with the same name already exists. Please rename the file and try again.")
            } else {
                // 不重複，允許上傳
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

class FileCell: UICollectionViewCell {
    let imageView = UIImageView()
    let nameLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        
        nameLabel.font = UIFont.systemFont(ofSize: 12)
        nameLabel.textAlignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)
        
        // AutoLayout Constraints
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            imageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 50),
            imageView.heightAnchor.constraint(equalToConstant: 50),
            
            nameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 5),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with fileURL: URL) {
        nameLabel.text = fileURL.lastPathComponent
        
        imageView.image = UIImage(systemName: "doc")
        
    }
}
