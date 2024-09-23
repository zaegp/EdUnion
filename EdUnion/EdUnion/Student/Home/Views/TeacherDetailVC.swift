//
//  TeacherDetailVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/14.
//

import UIKit

class TeacherDetailVC: UIViewController {
    
    var teacher: Teacher?
    var isFavorite: Bool = false
    var favoriteButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        favoriteButton = UIBarButtonItem(image: UIImage(systemName: isFavorite ? "suit.heart.fill" : "suit.heart"), style: .plain, target: self, action: #selector(favoriteButtonTapped))
        favoriteButton.tintColor = .mainOrange
        navigationItem.rightBarButtonItem = favoriteButton
        
        setupUI()
        checkIfTeacherIsFavorited()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: animated)
        
        tabBarController?.tabBar.isHidden = false
    }
    
    private func checkIfTeacherIsFavorited() {
        
        UserFirebaseService.shared.getStudentFollowList(studentID: studentID) { [weak self] followList, error in
            if let error = error {
                print("檢查 followList 時出錯: \(error.localizedDescription)")
            } else if let followList = followList {
                self?.isFavorite = followList.contains(self!.teacher!.id)
                self?.updateFavoriteButtonAppearance()
            }
        }
    }
    
    private func updateFavoriteButtonAppearance() {
        favoriteButton.image = UIImage(systemName: isFavorite ? "suit.heart.fill" : "suit.heart")
    }
    
    
    private func setupUI() {
        guard let teacher = teacher else { return }
        
        // 老師照片
        let imageView = UIImageView()
        if let photoURL = teacher.photoURL, let url = URL(string: photoURL) {
            imageView.kf.setImage(with: url)
        } else {
            imageView.image = UIImage(named: "default-avatar")  // 預設圖片
        }
        imageView.layer.cornerRadius = 50
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        // 老師名字
        let nameLabel = UILabel()
        nameLabel.text = teacher.name
        nameLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nameLabel)
        
        // 老師履歷
        let resumeLabel = UILabel()
        resumeLabel.text = teacher.resume.joined(separator: "\n")  // 將履歷的每一行拼接
        resumeLabel.font = UIFont.systemFont(ofSize: 16)
        resumeLabel.numberOfLines = 0
        resumeLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(resumeLabel)
        
        // 預約按鈕
        let bookButton = UIButton(type: .system)
        bookButton.setTitle("預約", for: .normal)
        bookButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        bookButton.backgroundColor = .mainOrange
        bookButton.setTitleColor(.white, for: .normal)
        bookButton.layer.cornerRadius = 10
        bookButton.translatesAutoresizingMaskIntoConstraints = false
        bookButton.addTarget(self, action: #selector(bookButtonTapped), for: .touchUpInside)
        view.addSubview(bookButton)
        
        // 進入聊天室按鈕
        let chatButton = UIButton(type: .system)
        chatButton.setTitle("進入聊天室", for: .normal)
        chatButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        chatButton.backgroundColor = .blue
        chatButton.setTitleColor(.white, for: .normal)
        chatButton.layer.cornerRadius = 10
        chatButton.translatesAutoresizingMaskIntoConstraints = false
        chatButton.addTarget(self, action: #selector(chatButtonTapped), for: .touchUpInside)
        view.addSubview(chatButton)
        
        // 設置約束
        NSLayoutConstraint.activate([
            // 老師照片
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            imageView.widthAnchor.constraint(equalToConstant: 100),
            imageView.heightAnchor.constraint(equalToConstant: 100),
            
            // 老師名字
            nameLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 16),
            nameLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // 老師履歷
            resumeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            resumeLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            resumeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // 預約按鈕
            bookButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bookButton.topAnchor.constraint(equalTo: resumeLabel.bottomAnchor, constant: 20),
            bookButton.widthAnchor.constraint(equalToConstant: 150),
            bookButton.heightAnchor.constraint(equalToConstant: 50),
            
            // 進入聊天室按鈕
            chatButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            chatButton.topAnchor.constraint(equalTo: bookButton.bottomAnchor, constant: 20),
            chatButton.widthAnchor.constraint(equalToConstant: 150),
            chatButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func bookButtonTapped() {
        let bookingVC = BookingVC()
        bookingVC.teacher = teacher
        navigationController?.pushViewController(bookingVC, animated: true)
    }
    
    @objc private func chatButtonTapped() {
        let chatVC = ChatVC()
        chatVC.teacherID = teacher?.id ?? ""  // 傳遞老師的 ID
        chatVC.studentID = studentID ?? ""    // 傳遞學生的 ID
        navigationController?.pushViewController(chatVC, animated: true)
    }
    
    @objc private func favoriteButtonTapped() {
        
        if isFavorite {
            // 如果已收藏，則移除收藏
            UserFirebaseService.shared.removeTeacherFromFollowList(studentID: studentID, teacherID: teacher!.id) { error in
                if let error = error {
                    print("從 followList 中移除老師時出錯: \(error.localizedDescription)")
                } else {
                    self.isFavorite = false
                    self.updateFavoriteButtonAppearance()
                    print("成功從 followList 中移除老師")
                }
            }
        } else {
            // 如果未收藏，則添加到收藏
            UserFirebaseService.shared.updateStudentList(studentID: studentID, teacherID: teacher!.id, listName: "followList") { error in
                if let error = error {
                    print("更新 followList 失敗: \(error)")
                } else {
                    print("成功更新 followList")
                }
            }
        }
    }
}

