//
//  ProfileVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/14.
//

import UIKit
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class ProfileVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    private let tableView = UITableView()
    private var userImageView: UIImageView!
    private let nameLabel = UILabel()
    private let userID = UserSession.shared.currentUserID
    private var userRole: String = UserDefaults.standard.string(forKey: "userRole") ?? "teacher"
    
    private var menuItems: [(title: String, icon: String, action: () -> Void)] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .myBackground
        setupTableView()
        setupTableHeaderView()
        setupMenuItems()
        updateUserInfo()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tabBarController?.tabBar.isHidden = true
        navigationController?.navigationBar.barTintColor = .myBackground
        navigationController?.navigationBar.shadowImage = UIImage()
    }
    
    // MARK: - Setup Methods
    
    private func setupTableView() {
        view.addSubview(tableView)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.separatorStyle = .none
        tableView.backgroundColor = .myBackground
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -80)
        ])
    }
    
    private func setupTableHeaderView() {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 130))
        headerView.backgroundColor = .myBackground
        
        userImageView = UIImageView()
        userImageView.tintColor = .myMessageCell
        userImageView.contentMode = .scaleAspectFill
        userImageView.layer.cornerRadius = 40
        userImageView.clipsToBounds = true
        userImageView.isUserInteractionEnabled = true
        userImageView.translatesAutoresizingMaskIntoConstraints = false
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapProfileImage))
        userImageView.addGestureRecognizer(tapGesture)
        
        nameLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        headerView.addSubview(userImageView)
        headerView.addSubview(nameLabel)
        
        NSLayoutConstraint.activate([
            userImageView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            userImageView.topAnchor.constraint(equalTo: headerView.topAnchor),
            userImageView.widthAnchor.constraint(equalToConstant: 80),
            userImageView.heightAnchor.constraint(equalToConstant: 80),
            
            nameLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            nameLabel.topAnchor.constraint(equalTo: userImageView.bottomAnchor, constant: 10)
        ])
        
        tableView.tableHeaderView = headerView
    }
    
    private func setupMenuItems() {
        if userRole == "teacher" {
            menuItems = [
                //                    ("分析", "arrow.right.to.line", { [weak self] in self?.navigateToChartView() }),
                ("可選時段", "calendar.badge.plus", { [weak self] in self?.navigateToAvailableTimeSlots() }),
                ("履歷", "list.bullet.clipboard", { [weak self] in self?.navigateToResume() }),
                ("所有學生列表", "person.text.rectangle.fill", { [weak self] in self?.navigateToAllStudents() }),
                ("教材", "folder", { [weak self] in self?.navigateToFiles() }),
                ("登出", "door.right.hand.open", logoutButtonTapped),
                ("刪除帳號", "trash", deleteAccountAction)
            ]
        } else {
            menuItems = [
                ("教材", "folder", { [weak self] in self?.navigateToFiles() }),
                ("刪除帳號", "trash", deleteAccountAction),
                ("登出帳號", "door.right.hand.open", logoutButtonTapped) // 添加登出
            ]
        }
    }
    
    @objc private func logoutButtonTapped() {
        let alertController = UIAlertController(title: "登出", message: "確定要登出嗎？", preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "確認", style: .destructive) { _ in
            self.performLogout()
        }
        alertController.addAction(confirmAction)
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func performLogout() {
        do {
            try Auth.auth().signOut()
            print("Successfully signed out")
            
            let loginView = AuthenticationView()
            let hostingController = UIHostingController(rootView: loginView)
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController = hostingController
                window.makeKeyAndVisible()
            }
        } catch let signOutError as NSError {
            print("Error signing out: \(signOutError)")
        }
    }
    
    private func deleteAccountAction() {
        let alertController = UIAlertController(title: "刪除帳號", message: "確定要刪除您的帳號嗎？這個操作無法恢復。", preferredStyle: .alert)
        
        let deleteAction = UIAlertAction(title: "刪除", style: .destructive) { _ in
            self.updateUserStatusToDeleting()
        }
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func updateUserStatusToDeleting() {
        guard let userID = userID, !userID.isEmpty else {
            print("Error: 無法取得使用者 ID")
            return
        }
        
        let collection = (userRole == "teacher") ? "teachers" : "students"
        
        let userRef = Firestore.firestore().collection(collection).document(userID)
        
        userRef.updateData(["status": "Deleting"]) { error in
            if let error = error {
                print("更新使用者狀態失敗: \(error.localizedDescription)")
            } else {
                print("使用者狀態已更新為 'Deleting'")
                self.logoutButtonTapped()
            }
        }
    }
    
    // MARK: - Navigation Methods
    
    private func navigateToChartView() {
        let chartView = ContentViews()
        let hostingController = UIHostingController(rootView: chartView)
        navigationController?.pushViewController(hostingController, animated: true)
    }
    
    private func navigateToAvailableTimeSlots() {
        let timeSlotsVC = AvailableTimeSlotsVC(teacherID: userID ?? "")
        navigationController?.pushViewController(timeSlotsVC, animated: true)
    }
    
    private func navigateToResume() {
        let resumeVC = ResumeVC()
        navigationController?.pushViewController(resumeVC, animated: true)
    }
    
    private func navigateToConfirmAppointments() {
        let confirmVC = ConfirmVC()
        navigationController?.pushViewController(confirmVC, animated: true)
    }
    
    private func navigateToAllStudents() {
        let studentListVC = AllStudentVC()
        navigationController?.pushViewController(studentListVC, animated: true)
    }
    
    private func navigateToFiles() {
        let filesVC = FilesVC()
        navigationController?.pushViewController(filesVC, animated: true)
    }
    
    // MARK: - User Info Methods
    
    private func updateUserInfo() {
        guard let userRole = UserDefaults.standard.string(forKey: "userRole") else {
            print("無法取得角色")
            return
        }
        
        let collection = (userRole == "teacher") ? "teachers" : "students"
        
        if userRole == "teacher" {
            UserFirebaseService.shared.fetchUser(from: collection, by: userID ?? "", as: Teacher.self) { [weak self] result in
                self?.handleFetchResult(result)
            }
        } else {
            UserFirebaseService.shared.fetchUser(from: collection, by: userID ?? "", as: Student.self) { [weak self] result in
                self?.handleFetchResult(result)
            }
        }
    }
    
    private func handleFetchResult<T: UserProtocol>(_ result: Result<T, Error>) {
        switch result {
        case .success(let user):
            self.updateUI(with: user.photoURL, name: user.fullName)
        case .failure(let error):
            print("查詢失敗: \(error.localizedDescription)")
        }
    }
    
    private func updateUI(with imageUrlString: String?, name: String) {
        if let url = URL(string: imageUrlString ?? "") {
            self.userImageView.kf.setImage(with: url, placeholder: UIImage(systemName: "person.crop.circle.fill"))
        } else {
            self.userImageView.image = UIImage(systemName: "person.crop.circle.fill")
        }
        self.nameLabel.text = name
    }
    
    // MARK: - Image Picker Methods
    
    @objc private func didTapProfileImage() {
        presentImagePicker(sourceType: .photoLibrary)
    }
    
    private func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        guard UIImagePickerController.isSourceTypeAvailable(sourceType) else { return }
        
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true)
    }
    
    // MARK: - UITableViewDelegate & DataSource Methods
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.backgroundColor = .myBackground
        let menuItem = menuItems[indexPath.row]
        
        let titleLabel = UILabel()
        titleLabel.text = menuItem.title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .myBlack
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let boldConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
        let iconImageView = UIImageView(image: UIImage(systemName: menuItem.icon, withConfiguration: boldConfig))
        iconImageView.tintColor = .myBlack
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        cell.contentView.addSubview(iconImageView)
        cell.contentView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 20),
            iconImageView.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 40),
            iconImageView.heightAnchor.constraint(equalToConstant: 40),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 30),
            titleLabel.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -20)
        ])
        
        cell.accessoryType = .disclosureIndicator
        cell.imageView?.tintColor = .myBlack
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        menuItems[indexPath.row].action()
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - UIImagePickerControllerDelegate Methods
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        if let editedImage = info[.editedImage] as? UIImage {
            userImageView.image = editedImage
            uploadProfileImage(editedImage)
        } else if let originalImage = info[.originalImage] as? UIImage {
            userImageView.image = originalImage
            uploadProfileImage(originalImage)
        }
    }
    
    private func uploadProfileImage(_ image: UIImage) {
        guard let userID = userID else {
            print("Error: User not logged in.")
            return
        }
        
        let storageRef = Storage.storage().reference().child("profile_images/\(userID).jpg")
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Error converting image to data.")
            return
        }
        
        storageRef.putData(imageData, metadata: nil) { [weak self] metadata, error in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Error getting download URL: \(error.localizedDescription)")
                    return
                }
                
                guard let downloadURL = url else {
                    print("Error: Download URL is nil.")
                    return
                }
                
                self?.saveImageURLToFirestore(downloadURL.absoluteString)
            }
        }
    }
    
    private func saveImageURLToFirestore(_ urlString: String) {
        guard let userID = userID else {
            print("Error: User not logged in.")
            return
        }
        
        let collection = (userRole == "teacher") ? "teachers" : "students"
        let userRef = Firestore.firestore().collection(collection).document(userID)
        
        userRef.updateData(["photoURL": urlString]) { error in
            if let error = error {
                print("Error saving image URL to Firestore: \(error.localizedDescription)")
            } else {
                print("Image URL successfully saved to Firestore.")
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
