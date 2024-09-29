//
//  ProfileVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/14.
//

import UIKit
import SwiftUI

class ProfileVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    private let tableView = UITableView()
    private var userImageView: UIImageView!
    let nameLabel = UILabel()
    let userID = UserSession.shared.currentUserID
    
    let data = [
        ("分析", "chart.bar"),
        ("可選時段", "calendar.badge.plus"),
        ("履歷", "list.bullet.clipboard"),
        ("待確認的預約", "bell"),
        ("所有學生列表", "person.3"),
        ("教材", "folder")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        setupTableView()
        setupTableHeaderView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tabBarController?.tabBar.isHidden = false
    }
    
    func setupTableView() {
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
    
    func setupTableHeaderView() {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 150))
        headerView.backgroundColor = .white
        
        userImageView = UIImageView()
        userImageView.contentMode = .scaleAspectFill
        userImageView.translatesAutoresizingMaskIntoConstraints = false
        userImageView.layer.cornerRadius = 40
        userImageView.clipsToBounds = true
        userImageView.isUserInteractionEnabled = true
        
        updateUserInfo()
        
        headerView.addSubview(userImageView)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapProfileImage))
        userImageView.addGestureRecognizer(tapGesture)
        
        nameLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
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
    
    func updateUserInfo() {
        guard let userRole = UserDefaults.standard.string(forKey: "userRole") else {
            print("無法取得角色")
            return
        }
        
        let collection = (userRole == "teacher") ? "teachers" : "students"
        print("查詢集合: \(collection)，使用者 ID: \(userID)")
        
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
            self.userImageView.kf.setImage(
                with: url,
                placeholder: UIImage(systemName: "person.crop.circle")?.withTintColor(.backButton, renderingMode: .alwaysOriginal)
            )
        } else {
            self.userImageView.image = UIImage(systemName: "person.crop.circle")
            self.userImageView.tintColor = .mainOrange
        }
        self.nameLabel.text = name
    }
    
    @objc func didTapProfileImage() {
        let actionSheet = UIAlertController(title: "更換大頭貼照", message: nil, preferredStyle: .actionSheet)
        
        // 只允許從圖庫選擇
        actionSheet.addAction(UIAlertAction(title: "從圖庫選擇", style: .default, handler: { [weak self] _ in
            self?.presentImagePicker(sourceType: .photoLibrary)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
    }
    
    func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            print("圖庫不可用")
            return
        }
        
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true)
    }
    
    // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
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
    
    // MARK: - TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let userRole = UserDefaults.standard.string(forKey: "userRole"), userRole == "teacher" {
            return data.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        cell.textLabel?.text = data[indexPath.row].0
        cell.imageView?.image = UIImage(systemName: data[indexPath.row].1)
        cell.accessoryType = .disclosureIndicator
        cell.imageView?.tintColor = UIColor(red: 0.92, green: 0.37, blue: 0.16, alpha: 1.00)
        cell.selectionStyle = .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedItem = data[indexPath.row].0
        
        switch selectedItem {
        case "分析":
            let chartView = ContentViews()
            let hostingController = UIHostingController(rootView: chartView)
            navigationController?.pushViewController(hostingController, animated: true)
        case "可選時段":
            let timeSlotsVC = AvailableTimeSlotsVC(teacherID: teacherID)
            navigationController?.pushViewController(timeSlotsVC, animated: true)
        case "履歷":
            let resumeVC = ResumeVC()
            navigationController?.pushViewController(resumeVC, animated: true)
        case "待確認的預約":
            let confirmVC = ConfirmVC()
            navigationController?.pushViewController(confirmVC, animated: true)
        case "所有學生列表":
            let studentListVC = AllStudentVC()
            navigationController?.pushViewController(studentListVC, animated: true)
        case "教材":
            let filesVC = FilesVC()
            navigationController?.pushViewController(filesVC, animated: true)
        default:
            break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

