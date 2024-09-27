//
//  FilesVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/26.
//

import UIKit

class FilesVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    var collectionView: UICollectionView!
    var selectedFiles: [URL] = []
    var files: [URL] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCollectionView()
        setupLongPressGesture()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "上傳文件", style: .plain, target: self, action: #selector(uploadFiles))
        
        print("View did load - FilesViewController initialized.")
    }
    
    func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 100, height: 120)
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.allowsMultipleSelection = true // 允許多選
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "fileCell")
        view.addSubview(collectionView)
        
        print("CollectionView set up successfully.")
    }
    
    func setupLongPressGesture() {
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        collectionView.addGestureRecognizer(longPressGesture)
        
        print("Long press gesture set up.")
    }
    
    @objc func handleLongPress(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            print("Long press gesture recognized.")
            // 進入多選模式
            collectionView.allowsMultipleSelection = true
        }
    }
    
    @objc func uploadFiles() {
        print("Upload button clicked.")
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.item])
        documentPicker.delegate = self
        present(documentPicker, animated: true, completion: nil)
        
        print("Document picker presented.")
    }
    
    // MARK: - UICollectionView DataSource & Delegate Methods
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("Number of items in section: \(files.count)")
        return files.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "fileCell", for: indexPath)
        
        if indexPath.item < files.count {
            let fileURL = files[indexPath.item]
            print("Configuring cell for file: \(fileURL.lastPathComponent)")
            
            let label = UILabel(frame: cell.contentView.bounds)
            label.text = fileURL.lastPathComponent
            label.textAlignment = .center
            cell.contentView.addSubview(label)
        } else {
            print("Error: indexPath.item (\(indexPath.item)) is out of bounds.")
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item < files.count {
            let selectedFile = files[indexPath.item]
            selectedFiles.append(selectedFile)
            print("File selected: \(selectedFile.lastPathComponent)")
        } else {
            print("Error: Selected index out of bounds.")
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if indexPath.item < files.count {
            let deselectedFile = files[indexPath.item]
            if let index = selectedFiles.firstIndex(of: deselectedFile) {
                selectedFiles.remove(at: index)
                print("File deselected: \(deselectedFile.lastPathComponent)")
            }
        } else {
            print("Error: Deselected index out of bounds.")
        }
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
        
        files.append(contentsOf: urls)
        collectionView.reloadData()
        print("Files added and collection view reloaded. Total files count: \(files.count)")
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("Document picker was cancelled")
    }
}

