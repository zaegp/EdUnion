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

class ProfileVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    private let tableView = UITableView()
    private var userImageView: UIImageView!
    private let nameLabel = UILabel()
    private let userID = UserSession.shared.currentUserID
    private var userRole: String = UserDefaults.standard.string(forKey: "userRole") ?? "teacher"
    
    private var menuItems: [(title: String, icon: String, action: () -> Void)] = []
    private let logoutButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        setupTableView()
        setupTableHeaderView()
        setupLogoutButton()
        setupMenuItems()
        updateUserInfo()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = false
    }
    
    // MARK: - Setup Methods
    
    private func setupTableView() {
        view.addSubview(tableView)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupTableHeaderView() {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 150))
        headerView.backgroundColor = .white
        
        userImageView = UIImageView()
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
            userImageView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 20),
            userImageView.widthAnchor.constraint(equalToConstant: 80),
            userImageView.heightAnchor.constraint(equalToConstant: 80),
            
            nameLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            nameLabel.topAnchor.constraint(equalTo: userImageView.bottomAnchor, constant: 10)
        ])
        
        tableView.tableHeaderView = headerView
    }
    
    private func setupLogoutButton() {
            logoutButton.setTitle("登出", for: .normal)
            logoutButton.setTitleColor(.white, for: .normal)
            logoutButton.backgroundColor = .systemRed
            logoutButton.layer.cornerRadius = 10
            logoutButton.translatesAutoresizingMaskIntoConstraints = false
            logoutButton.addTarget(self, action: #selector(logoutButtonTapped), for: .touchUpInside)
            
            view.addSubview(logoutButton)
            
            NSLayoutConstraint.activate([
                logoutButton.heightAnchor.constraint(equalToConstant: 50),
                logoutButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
                logoutButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
                logoutButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
            ])
        }
    
    @objc private func logoutButtonTapped() {
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
    
    private func setupMenuItems() {
        if userRole == "teacher" {
            menuItems = [
                ("分析", "chart.bar", { [weak self] in self?.navigateToChartView() }),
                ("可選時段", "calendar.badge.plus", { [weak self] in self?.navigateToAvailableTimeSlots() }),
                ("履歷", "list.bullet.clipboard", { [weak self] in self?.navigateToResume() }),
                ("所有學生列表", "person.3", { [weak self] in self?.navigateToAllStudents() }),
                ("教材", "folder", { [weak self] in self?.navigateToFiles() }),
                ("刪除帳號", "trash", deleteAccountAction)
            ]
        } else {
            menuItems = [
                ("教材", "folder", { [weak self] in self?.navigateToFiles() }),
                ("刪除帳號", "trash", deleteAccountAction)
            ]
        }
    }
    
    private func deleteAccountAction() {
        // 顯示確認刪除帳號的警告
        let alertController = UIAlertController(title: "刪除帳號", message: "確定要刪除您的帳號嗎？這個操作無法恢復。", preferredStyle: .alert)
        
        let deleteAction = UIAlertAction(title: "刪除", style: .destructive) { _ in
            // 呼叫 Firebase 更新 status 為 "Deleting"
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
            self.userImageView.kf.setImage(with: url, placeholder: UIImage(systemName: "person.crop.circle"))
        } else {
            self.userImageView.image = UIImage(systemName: "person.crop.circle")
        }
        self.nameLabel.text = name
    }
    
    // MARK: - Image Picker Methods
    
    @objc private func didTapProfileImage() {
        let actionSheet = UIAlertController(title: "更換大頭貼照", message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "從圖庫選擇", style: .default) { [weak self] _ in
            self?.presentImagePicker(sourceType: .photoLibrary)
        })
        actionSheet.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        present(actionSheet, animated: true)
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
        let menuItem = menuItems[indexPath.row]
        cell.textLabel?.text = menuItem.title
        cell.imageView?.image = UIImage(systemName: menuItem.icon)
        cell.accessoryType = .disclosureIndicator
        cell.imageView?.tintColor = UIColor.mainOrange
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
        } else if let originalImage = info[.originalImage] as? UIImage {
            userImageView.image = originalImage
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
