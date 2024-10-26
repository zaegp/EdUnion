//
//  ProfileVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/14.
//

import UIKit
import SwiftUI
import SafariServices

struct MenuItem {
    let title: String
    let icon: String
    let action: () -> Void
}

class ProfileVC: UIViewController, UINavigationControllerDelegate {
    private var userImageView: UIImageView!
    private let nameLabel = UILabel()
    private let tableView = UITableView()
    
    private let userID = UserSession.shared.unwrappedUserID
    private var userRole: String = UserDefaults.standard.string(forKey: "userRole") ?? "teacher"
    private var userCollection: String {
        return (userRole == "teacher") ? "teachers" : "students"
    }
    private var menuItems: [MenuItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .myBackground
        
        setupTableHeaderView()
        updateUserInfo()
        
        setupTableView()
        setupMenuItems()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.barTintColor = .myBackground
        navigationController?.navigationBar.shadowImage = UIImage()
        
        updateUserInfo()
        
        tabBarController?.tabBar.isHidden = true
        if let tabBarController = self.tabBarController as? TabBarController {
            tabBarController.setCustomTabBarHidden(false, animated: true)
        }
    }
    
    // MARK: - Setup
    private func setupTableHeaderView() {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 130))
        headerView.backgroundColor = .clear
        
        userImageView = UIImageView()
        userImageView.tintColor = .myTint
        userImageView.contentMode = .scaleAspectFill
        userImageView.layer.cornerRadius = 40
        userImageView.clipsToBounds = true
        userImageView.isUserInteractionEnabled = true
        userImageView.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(userImageView)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapProfileImage))
        userImageView.addGestureRecognizer(tapGesture)
        
        nameLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
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
                MenuItem(
                    title: "可選時段",
                    icon: "calendar.badge.plus",
                    action: { [weak self] in self?.navigateToAvailableTimeSlots() }
                ),
                MenuItem(
                    title: "履歷",
                    icon: "list.bullet.clipboard",
                    action: { [weak self] in self?.navigateToResume() }
                ),
                MenuItem(
                    title: "學生名單",
                    icon: "person.text.rectangle",
                    action: { [weak self] in self?.navigateToAllStudents() }
                ),
                MenuItem(title: "教材", icon: "folder", action: { [weak self] in self?.navigateToFiles() }),
                MenuItem(title: "隱私權政策", icon: "lock.shield", action: { [weak self] in self?.openPrivacyPolicy() }),
                MenuItem(title: "登出", icon: "door.right.hand.open", action: logoutButtonTapped),
                MenuItem(title: "刪除帳號", icon: "trash", action: deleteAccountAction)
            ]
        } else {
            menuItems = [
                MenuItem(title: "教材", icon: "folder", action: { [weak self] in self?.navigateToFiles() }),
                MenuItem(title: "隱私權政策", icon: "lock.shield", action: { [weak self] in self?.openPrivacyPolicy() }),
                MenuItem(title: "登出帳號", icon: "door.right.hand.open", action: logoutButtonTapped),
                MenuItem(title: "刪除帳號", icon: "trash", action: deleteAccountAction)
            ]
        }
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -80)
        ])
    }
    
    // MARK: - Navigation Methods
    private func navigateToAvailableTimeSlots() {
        let availableTimeSlotsVC = AvailableTimeSlotsVC()
        navigationController?.pushViewController(availableTimeSlotsVC, animated: true)
    }
    
    private func navigateToResume() {
        let resumeVC = ResumeVC()
        navigationController?.pushViewController(resumeVC, animated: true)
    }
    
    private func navigateToAllStudents() {
        let studentListVC = StudentListVC()
        navigationController?.pushViewController(studentListVC, animated: true)
    }
    
    private func navigateToFiles() {
        let filesVC = FilesVC()
        navigationController?.pushViewController(filesVC, animated: true)
    }
    
    // MARK: - User Info
    private func updateUserInfo() {
        guard let userRole = UserDefaults.standard.string(forKey: "userRole") else {
            print("無法取得角色")
            return
        }
        
        if userRole == "teacher" {
            UserFirebaseService.shared.fetchUser(from: userCollection, by: userID, as: Teacher.self) { [weak self] result in
                self?.handleFetchResult(result)
            }
        } else {
            UserFirebaseService.shared.fetchUser(from: userCollection, by: userID, as: Student.self) { [weak self] result in
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
    
    // MARK: - Privacy Policy
    private func openPrivacyPolicy() {
        guard let url = URL(
            string: "https://www.privacypolicies.com/live/8f20be33-d0b5-4f8b-a724-4c02a815b87a"
        ) else { return }
        let safariVC = SFSafariViewController(url: url)
        present(safariVC, animated: true, completion: nil)
    }
    
    // MARK: - Logout and Delete
    @objc private func logoutButtonTapped() {
        let alertController = UIAlertController(title: "登出", message: "確定要登出嗎？", preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "確認", style: .destructive) { _ in
            UserSession.shared.signOut { error in
                if let error = error {
                    print("Error signing out: \(error.localizedDescription)")
                } else {
                    print("Successfully signed out.")
                    let loginView = AuthenticationView()
                    let hostingController = UIHostingController(rootView: loginView)
                    
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        window.rootViewController = hostingController
                        window.makeKeyAndVisible()
                    }
                }
            }
        }
        alertController.addAction(confirmAction)
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func deleteAccountAction() {
        let alertController = UIAlertController(
            title: "刪除帳號",
            message: "您在30天內重新登錄此帳號即可保留原本的資料",
            preferredStyle: .alert)
        
        let deleteAction = UIAlertAction(title: "刪除", style: .destructive) { _ in
            UserSession.shared.deleteAccount(userRole: self.userRole) { error in
                if let error = error {
                    print("Error deleting account: \(error.localizedDescription)")
                } else {
                    print("Account deletion process started.")
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
}

extension ProfileVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
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
        
        let boldConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .regular)
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
}

extension ProfileVC: UIImagePickerControllerDelegate {
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
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
        UserFirebaseService.shared.uploadProfileImage(image, forUserID: userID, userRole: userRole) { result in
            switch result {
            case .success:
                print("Image successfully uploaded and URL saved to Firestore.")
            case .failure(let error):
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
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
}
