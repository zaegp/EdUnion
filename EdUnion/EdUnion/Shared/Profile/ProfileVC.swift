//
//  ProfileVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/14.
//

import UIKit

class ProfileVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // 創建 TableView
    private let tableView = UITableView()
    private var userImageView: UIImageView!

    let data = [
        ("分析", "chart.bar"),
        ("可選時段", "calendar.badge.plus"),
        ("履歷", "list.bullet.clipboard"),
        ("幫助", "questionmark.circle")
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        setupTableView()
        setupTableHeaderView()  // 添加個人資訊 header

    }

    // 設置 TableView
    func setupTableView() {
        // 將 TableView 添加到當前視圖
        view.addSubview(tableView)

        // 設置代理和數據源
        tableView.delegate = self
        tableView.dataSource = self

        // 註冊 TableView 的 Cell
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

        // 使用自動佈局設置 TableView 的位置和大小
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
            
            // 添加使用者頭像
            userImageView = UIImageView(image: UIImage(systemName: "person.circle"))
            userImageView.tintColor = UIColor(red: 0.92, green: 0.37, blue: 0.16, alpha: 1.00)
            userImageView.contentMode = .scaleAspectFit
            userImageView.translatesAutoresizingMaskIntoConstraints = false
            userImageView.layer.cornerRadius = 40
            userImageView.clipsToBounds = true
            userImageView.isUserInteractionEnabled = true  // 允許用戶交互
            
            headerView.addSubview(userImageView)
            
            // 添加點擊手勢到頭像，讓用戶可以點擊
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapProfileImage))
            userImageView.addGestureRecognizer(tapGesture)
            
            // 添加使用者姓名
            let nameLabel = UILabel()
            nameLabel.text = "User Name"
            nameLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
            nameLabel.translatesAutoresizingMaskIntoConstraints = false
            
            headerView.addSubview(nameLabel)
            
            // 添加約束
            NSLayoutConstraint.activate([
                // 頭像
                userImageView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
                userImageView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 20),
                userImageView.widthAnchor.constraint(equalToConstant: 80),
                userImageView.heightAnchor.constraint(equalToConstant: 80),
                
                // 使用者名稱
                nameLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
                nameLabel.topAnchor.constraint(equalTo: userImageView.bottomAnchor, constant: 10)
            ])
            
            // 設置 TableView 的 header
            tableView.tableHeaderView = headerView
        }
    
    @objc func didTapProfileImage() {
        let actionSheet = UIAlertController(title: "更換大頭貼照", message: nil, preferredStyle: .actionSheet)
            
            // 選擇從照片庫
            actionSheet.addAction(UIAlertAction(title: "從圖庫選擇", style: .default, handler: { [weak self] _ in
                self?.presentImagePicker(sourceType: .photoLibrary)
            }))
            
            // 選擇從相機
            actionSheet.addAction(UIAlertAction(title: "拍照", style: .default, handler: { [weak self] _ in
                self?.presentImagePicker(sourceType: .camera)
            }))
            
            // 取消選擇
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
            
            // 從選擇器中獲取編輯後的圖片
            if let editedImage = info[.editedImage] as? UIImage {
                userImageView.image = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                userImageView.image = originalImage
            }
        }
        
        // 如果取消選擇圖片
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true, completion: nil)
        }
    
    // MARK: - UITableViewDataSource

    // 返回行數
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    // 配置每個 Cell 的內容
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        // 設置標準樣式和 accessory type
        cell.textLabel?.text = data[indexPath.row].0
        cell.imageView?.image = UIImage(systemName: data[indexPath.row].1)
        cell.accessoryType = .disclosureIndicator // 顯示右側的箭頭
        cell.imageView?.tintColor = UIColor(red: 0.92, green: 0.37, blue: 0.16, alpha: 1.00)
        cell.selectionStyle = .none

        return cell
    }

    // MARK: - UITableViewDelegate

    // 設置 Cell 的高度
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 获取点击的 cell 的索引
        let selectedItem = data[indexPath.row].0
        
        // 根据不同的 cell 跳转到相应的 ViewController
        switch selectedItem {
        case "分析": break
//            let analysisVC = AnalysisViewController()  // 假设你已经有一个 AnalysisViewController 类
//            navigationController?.pushViewController(analysisVC, animated: true)
        
        case "可選時段":
            let timeSlotsVC = AvailableTimeSlotsVC(teacherID: "001")  // 假设你有一个 TimeSlotsViewController 类
            navigationController?.pushViewController(timeSlotsVC, animated: true)
        
        case "履歷": break
//            let resumeVC = ResumeViewController()  // 假设你有一个 ResumeViewController 类
//            navigationController?.pushViewController(resumeVC, animated: true)
        
        case "幫助": break
//            let helpVC = HelpViewController()  // 假设你有一个 HelpViewController 类
//            navigationController?.pushViewController(helpVC, animated: true)
        
        default:
            break
        }
        
        // 取消选中状态
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

