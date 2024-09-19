//
//  ProfileVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/14.
//

import UIKit

class ProfileVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    private let tableView = UITableView()
    private var userImageView: UIImageView!
    
    let data = [
        ("分析", "chart.bar"),
        ("可選時段", "calendar.badge.plus"),
        ("履歷", "list.bullet.clipboard"),
        ("待確認的預約", "bell")
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
        headerView.backgroundColor = UIColor.systemGray6
        
        userImageView = UIImageView(image: UIImage(systemName: "person.circle"))
        userImageView.tintColor = UIColor(red: 0.92, green: 0.37, blue: 0.16, alpha: 1.00)
        userImageView.contentMode = .scaleAspectFit
        userImageView.translatesAutoresizingMaskIntoConstraints = false
        userImageView.layer.cornerRadius = 40
        userImageView.clipsToBounds = true
        userImageView.isUserInteractionEnabled = true
        
        headerView.addSubview(userImageView)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapProfileImage))
        userImageView.addGestureRecognizer(tapGesture)
        
        let nameLabel = UILabel()
        nameLabel.text = "姓名"
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
    
    @objc func didTapProfileImage() {
        let actionSheet = UIAlertController(title: "更換大頭貼照", message: nil, preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "從圖庫選擇", style: .default, handler: { [weak self] _ in
            self?.presentImagePicker(sourceType: .photoLibrary)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "拍照", style: .default, handler: { [weak self] _ in
            self?.presentImagePicker(sourceType: .camera)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
    }
    
    func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        guard UIImagePickerController.isSourceTypeAvailable(sourceType) else {
            print("Source type not available")
            return
        }
        
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
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
        return data.count
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
            break
        case "可選時段":
            let timeSlotsVC = AvailableTimeSlotsVC(teacherID: teacherID)
            navigationController?.pushViewController(timeSlotsVC, animated: true)
        case "履歷":
            let resumeVC = ResumeVC()
            navigationController?.pushViewController(resumeVC, animated: true)
        case "待確認的預約":
            let confirmVC = ConfirmVC()
            navigationController?.pushViewController(confirmVC, animated: true)
        default:
            break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
