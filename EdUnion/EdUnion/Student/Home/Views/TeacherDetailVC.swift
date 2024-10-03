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
    var ellipsisButton: UIBarButtonItem!
    private let imageView = UIImageView()
    private let nameLabel = UILabel()
    private let totalCoursesLabel = UILabel()
    private let subjectLabel = UILabel()
    private let educationLabel = UILabel()
    private let experienceLabel = UILabel()
    private let introduceLabel = UILabel()
    private let bookButton = UIButton(type: .system)
    private let chatButton = UIButton(type: .system)
    let userID = UserSession.shared.currentUserID
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        favoriteButton = UIBarButtonItem(image: UIImage(systemName: isFavorite ? "suit.heart.fill" : "suit.heart"), style: .plain, target: self, action: #selector(favoriteButtonTapped))
        favoriteButton.tintColor = .mainOrange
        ellipsisButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), style: .plain, target: self, action: #selector(ellipsisButtonTapped))
        ellipsisButton.tintColor = .mainOrange
        
        navigationItem.rightBarButtonItems = [favoriteButton, ellipsisButton]
        
        setupUI()
        checkIfTeacherIsFavorited()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: animated)
        
        tabBarController?.tabBar.isHidden = false
    }
    
    @objc private func ellipsisButtonTapped() {
            // 彈出 Alert 進行封鎖確認
            let alertController = UIAlertController(title: "封鎖", message: "您確定要封鎖這位老師嗎？", preferredStyle: .alert)
            
            let confirmAction = UIAlertAction(title: "確認", style: .destructive) { _ in
                // 呼叫封鎖用戶的方法
                self.blockUser()
            }
            
            let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
            
            alertController.addAction(confirmAction)
            alertController.addAction(cancelAction)
            
            present(alertController, animated: true, completion: nil)
        }
        
        private func blockUser() {
            guard let teacherID = teacher?.id else { return }
            UserFirebaseService.shared.blockUser(blockID: teacherID, isTeacher: false) { error in
                if let error = error {
                    print("封鎖老師失敗: \(error.localizedDescription)")
                } else {
                    print("成功封鎖老師")
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    
    private func checkIfTeacherIsFavorited() {
        
        UserFirebaseService.shared.getStudentFollowList(studentID: userID ?? "") { [weak self] followList, error in
            if let error = error {
                print("檢查 followList 時出錯: \(error.localizedDescription)")
            } else if let followList = followList {
                self?.isFavorite = followList.contains(self!.teacher!.userID)
                self?.updateFavoriteButtonAppearance()
            }
        }
    }
    
    private func updateFavoriteButtonAppearance() {
        favoriteButton.image = UIImage(systemName: isFavorite ? "suit.heart.fill" : "suit.heart")
    }
    
    private func setupUI() {
        guard let teacher = teacher else { return }
        
        if let photoURL = teacher.photoURL, let url = URL(string: photoURL) {
            imageView.kf.setImage(
                with: url,
                placeholder: UIImage(systemName: "person.circle.fill")?
                    .withTintColor(.backButton, renderingMode: .alwaysOriginal)
                
            )
        } else {
            imageView.image = UIImage(systemName: "person.circle.fill")
            imageView.tintColor = .backButton
            print("沒有圖片 URL")
        }
        
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 50
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        nameLabel.text = teacher.fullName
        nameLabel.textAlignment = .center
        nameLabel.font = UIFont.boldSystemFont(ofSize: 18)
        nameLabel.textColor = .black
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nameLabel)
        
        totalCoursesLabel.text = "總課程數: \(teacher.totalCourses)"
        totalCoursesLabel.textAlignment = .center
        totalCoursesLabel.font = UIFont.systemFont(ofSize: 14)
        totalCoursesLabel.textColor = .black
        totalCoursesLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(totalCoursesLabel)
        
        subjectLabel.text = "教學科目: \(teacher.resume[3])"
        subjectLabel.font = UIFont.systemFont(ofSize: 14)
        subjectLabel.textColor = .black
        subjectLabel.textAlignment = .center
        subjectLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(subjectLabel)
        
        educationLabel.text = "學歷: \(teacher.resume[0])"
        educationLabel.font = UIFont.systemFont(ofSize: 14)
        educationLabel.textColor = .black
        educationLabel.textAlignment = .center
        educationLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(educationLabel)
        
        experienceLabel.text = "教學經驗: \(teacher.resume[1])"
        experienceLabel.font = UIFont.systemFont(ofSize: 14)
        experienceLabel.textColor = .black
        experienceLabel.textAlignment = .center
        experienceLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(experienceLabel)
        
        introduceLabel.text = "自我介紹: \(teacher.resume[2])"
        introduceLabel.numberOfLines = 0
        introduceLabel.font = UIFont.systemFont(ofSize: 14)
        introduceLabel.textColor = .black
        introduceLabel.textAlignment = .center
        introduceLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(introduceLabel)
        
        bookButton.setTitle("預約", for: .normal)
        bookButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        bookButton.backgroundColor = .mainOrange
        bookButton.setTitleColor(.white, for: .normal)
        bookButton.layer.cornerRadius = 10
        bookButton.translatesAutoresizingMaskIntoConstraints = false
        bookButton.addTarget(self, action: #selector(bookButtonTapped), for: .touchUpInside)
        view.addSubview(bookButton)
        
        chatButton.setTitle("進入聊天室", for: .normal)
        chatButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        chatButton.backgroundColor = .mainOrange
        chatButton.setTitleColor(.white, for: .normal)
        chatButton.layer.cornerRadius = 10
        chatButton.translatesAutoresizingMaskIntoConstraints = false
        chatButton.addTarget(self, action: #selector(chatButtonTapped), for: .touchUpInside)
        view.addSubview(chatButton)
        
        setupConstraint()
        
    }
    
    func setupConstraint() {
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            imageView.widthAnchor.constraint(equalToConstant: 100),
            imageView.heightAnchor.constraint(equalToConstant: 100),
            
            nameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            totalCoursesLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            totalCoursesLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            totalCoursesLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            subjectLabel.topAnchor.constraint(equalTo: totalCoursesLabel.bottomAnchor, constant: 8),
            subjectLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            subjectLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            educationLabel.topAnchor.constraint(equalTo: subjectLabel.bottomAnchor, constant: 8),
            educationLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            educationLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            experienceLabel.topAnchor.constraint(equalTo: educationLabel.bottomAnchor, constant: 8),
            experienceLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            experienceLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            introduceLabel.topAnchor.constraint(equalTo: experienceLabel.bottomAnchor, constant: 8),
            introduceLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            introduceLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            bookButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bookButton.topAnchor.constraint(equalTo: introduceLabel.bottomAnchor, constant: 20),
            bookButton.widthAnchor.constraint(equalToConstant: 150),
            bookButton.heightAnchor.constraint(equalToConstant: 50),
            
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
        chatVC.teacher = teacher
        chatVC.student?.id = userID ?? ""
        navigationController?.pushViewController(chatVC, animated: true)
    }
    
    @objc private func favoriteButtonTapped() {
        if isFavorite {
            UserFirebaseService.shared.removeTeacherFromFollowList(studentID: userID ?? "", teacherID: teacher!.userID) { error in
                if let error = error {
                    print("從 followList 中移除老師時出錯: \(error.localizedDescription)")
                } else {
                    self.isFavorite = false
                    self.updateFavoriteButtonAppearance()
                    print("成功從 followList 中移除老師")
                }
            }
        } else {
            UserFirebaseService.shared.updateStudentList(studentID: userID ?? "", teacherID: teacher!.id, listName: "followList") { error in
                if let error = error {
                    print("更新 followList 失敗: \(error)")
                } else {
                    self.isFavorite = true
                    self.updateFavoriteButtonAppearance()
                    print("成功更新 followList")
                }
            }
        }
    }
}

