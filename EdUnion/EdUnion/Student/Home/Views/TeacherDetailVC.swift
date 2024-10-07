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
        
        private let scrollView = UIScrollView()
        private let contentStackView = UIStackView()
        
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
            
            view.backgroundColor = .myBackground
            setupNavigationBar()
            setupScrollView()
            setupUI()
            checkIfTeacherIsFavorited()
        }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            
            navigationController?.setNavigationBarHidden(false, animated: animated)
            
            if let tabBarController = self.tabBarController as? TabBarController {
                tabBarController.setCustomTabBarHidden(true, animated: true)
            }
        }
        
        private func setupNavigationBar() {
            navigationItem.title = "老師詳情"
            
            favoriteButton = UIBarButtonItem(image: UIImage(systemName: isFavorite ? "heart.fill" : "heart"), style: .plain, target: self, action: #selector(favoriteButtonTapped))
            favoriteButton.tintColor = .mainOrange
            ellipsisButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), style: .plain, target: self, action: #selector(ellipsisButtonTapped))
            ellipsisButton.tintColor = .mainOrange
            
            navigationItem.rightBarButtonItems = [ellipsisButton, favoriteButton]
        }
        
        private func setupScrollView() {
            scrollView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(scrollView)
            
            NSLayoutConstraint.activate([
                scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
            
            contentStackView.axis = .vertical
            contentStackView.alignment = .fill
            contentStackView.spacing = 16
            contentStackView.translatesAutoresizingMaskIntoConstraints = false
            scrollView.addSubview(contentStackView)
            
            NSLayoutConstraint.activate([
                contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
                contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
                contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
                contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
                contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
            ])
        }
    
    @objc private func ellipsisButtonTapped() {
            let alertController = UIAlertController(title: "封鎖", message: "您確定要封鎖這位老師嗎？", preferredStyle: .alert)
            
            let confirmAction = UIAlertAction(title: "確認", style: .destructive) { _ in
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
                    placeholder: UIImage(systemName: "person.crop.circle.fill")?
                        .withTintColor(.backButton, renderingMode: .alwaysOriginal)
                )
            } else {
                imageView.image = UIImage(systemName: "person.crop.circle.fill")
                imageView.tintColor = .backButton
            }
            imageView.contentMode = .scaleAspectFill
            imageView.layer.cornerRadius = 50
            imageView.clipsToBounds = true
            imageView.translatesAutoresizingMaskIntoConstraints = false
            let imageContainer = UIView()
            imageContainer.addSubview(imageView)
            contentStackView.addArrangedSubview(imageContainer)
            
            NSLayoutConstraint.activate([
                imageView.centerXAnchor.constraint(equalTo: imageContainer.centerXAnchor),
                imageView.topAnchor.constraint(equalTo: imageContainer.topAnchor),
                imageView.bottomAnchor.constraint(equalTo: imageContainer.bottomAnchor),
                imageView.widthAnchor.constraint(equalToConstant: 100),
                imageView.heightAnchor.constraint(equalToConstant: 100)
            ])
            
            nameLabel.text = teacher.fullName
            nameLabel.textAlignment = .center
            nameLabel.font = UIFont.boldSystemFont(ofSize: 24)
            nameLabel.textColor = .black
            contentStackView.addArrangedSubview(nameLabel)
            
            let separator1 = createSeparator()
            contentStackView.addArrangedSubview(separator1)
            
            let infoLabels = [
                ("已上課程數", "\(teacher.totalCourses)"),
                ("教學科目", teacher.resume[3]),
                ("學歷", teacher.resume[0]),
                ("教學經驗", teacher.resume[1])
            ]
            
            let infoStackView = UIStackView()
            infoStackView.axis = .vertical
            infoStackView.spacing = 8
            infoStackView.alignment = .leading
            contentStackView.addArrangedSubview(infoStackView)
            
            for (title, value) in infoLabels {
                let label = UILabel()
                label.text = "\(title)：\(value)"
                label.font = UIFont.systemFont(ofSize: 16)
                label.textColor = .darkGray
                infoStackView.addArrangedSubview(label)
            }
            
            let separator2 = createSeparator()
            contentStackView.addArrangedSubview(separator2)
            
        introduceLabel.text = "自我介绍：\n\(teacher.resume[2] ?? "未提供")"
        introduceLabel.numberOfLines = 0
        introduceLabel.font = UIFont.systemFont(ofSize: 16)
        introduceLabel.textColor = .black
        contentStackView.addArrangedSubview(introduceLabel)
        
            let separator3 = createSeparator()
            contentStackView.addArrangedSubview(separator3)
        
        let spacingView = UIView()
            spacingView.translatesAutoresizingMaskIntoConstraints = false
            spacingView.heightAnchor.constraint(equalToConstant: 30).isActive = true
            contentStackView.addArrangedSubview(spacingView)
            
            let buttonStackView = UIStackView()
            buttonStackView.axis = .vertical
            buttonStackView.spacing = 16
            buttonStackView.alignment = .fill
            contentStackView.addArrangedSubview(buttonStackView)
            
            bookButton.setTitle("預約", for: .normal)
            bookButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
            bookButton.backgroundColor = .mainOrange
            bookButton.setTitleColor(.white, for: .normal)
            bookButton.layer.cornerRadius = 10
            bookButton.translatesAutoresizingMaskIntoConstraints = false
            bookButton.addTarget(self, action: #selector(bookButtonTapped), for: .touchUpInside)
            buttonStackView.addArrangedSubview(bookButton)
            
            chatButton.setTitle("進入聊天室", for: .normal)
            chatButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
            chatButton.backgroundColor = .mainOrange
            chatButton.setTitleColor(.white, for: .normal)
            chatButton.layer.cornerRadius = 10
            chatButton.translatesAutoresizingMaskIntoConstraints = false
            chatButton.addTarget(self, action: #selector(chatButtonTapped), for: .touchUpInside)
            buttonStackView.addArrangedSubview(chatButton)
            
            NSLayoutConstraint.activate([
                bookButton.heightAnchor.constraint(equalToConstant: 50),
                chatButton.heightAnchor.constraint(equalToConstant: 50)
            ])
        }
    
    private func createSeparator() -> UIView {
           let separator = UIView()
           separator.backgroundColor = .lightGray
           separator.translatesAutoresizingMaskIntoConstraints = false
           separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
           return separator
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

