//
//  IntroVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/26.
//

import UIKit
import FirebaseFirestore
import FirebaseStorage

class IntroVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    let userID = UserSession.shared.currentUserID
    
    let profileImageView = UIImageView()
    
    let educationLabel = UILabel()
    let educationTextField = PaddedTextField()
    
    let experienceLabel = UILabel()
    let experienceTextField = PaddedTextField()
    
    let introLabel = UILabel()
    let introTextView = UITextView()
    
    let subjectsLabel = UILabel()
    let subjectsTextField = PaddedTextField()
    
    let hourlyRateLabel = UILabel()
    let hourlyRateTextField = PaddedTextField()
    
    let saveButton = UIButton(type: .system)

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        tabBarController?.tabBar.isHidden = true
        if let tabBarController = self.tabBarController as? TabBarController {
            tabBarController.setCustomTabBarHidden(true, animated: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .myBackground
        setupUI()
        setupKeyboardDismissRecognizer()
        
        navigationController?.navigationBar.barTintColor = .myBackground
        navigationController?.navigationBar.shadowImage = UIImage()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(uploadImageButtonTapped))
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(tapGesture)
    }
    
    func setupUI() {
        profileImageView.image = UIImage(systemName: "person.crop.circle.badge.plus")
        profileImageView.tintColor = .myBlack
        profileImageView.contentMode = .scaleAspectFit
        profileImageView.layer.cornerRadius = 50
        profileImageView.clipsToBounds = true
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        
        educationLabel.text = "- 學歷 -"
        experienceLabel.text = "- 教學經驗 -"
        introLabel.text = "- 自我介紹 -"
        subjectsLabel.text = "- 教學科目 -"
        hourlyRateLabel.text = "- 時薪 -"
        
        for label in [educationLabel, experienceLabel, introLabel, subjectsLabel, hourlyRateLabel] {
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            label.adjustsFontSizeToFitWidth = true // 調整字體大小以適應寬度
            label.minimumScaleFactor = 0.5 // 最小縮放比例
        }
        
        for textField in [educationTextField, experienceTextField, subjectsTextField, hourlyRateTextField] {
            textField.borderStyle = .none
            textField.layer.cornerRadius = 10
            textField.layer.borderWidth = 1
            textField.layer.borderColor = UIColor.mainTint.cgColor
            textField.clipsToBounds = true
            textField.backgroundColor = .systemBackground
            textField.textAlignment = .left
            textField.horizontalPadding = 10
            textField.heightAnchor.constraint(equalToConstant: 50).isActive = true
            textField.tintColor = .mainOrange
        }
        
        introTextView.layer.cornerRadius = 10
        introTextView.font = UIFont.systemFont(ofSize: 16)
        introTextView.isScrollEnabled = true
        introTextView.contentInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        introTextView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        introTextView.tintColor = .mainOrange
        
        saveButton.setTitle("保存", for: .normal)
        saveButton.backgroundColor = .mainOrange
        saveButton.tintColor = .white
        saveButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        saveButton.layer.cornerRadius = 30
        saveButton.heightAnchor.constraint(equalToConstant: 60).isActive = true
        saveButton.addTarget(self, action: #selector(saveChanges), for: .touchUpInside)
        
        let stackView = UIStackView(arrangedSubviews: [
            createStackView(with: educationLabel, and: educationTextField),
            createStackView(with: experienceLabel, and: experienceTextField),
            createStackView(with: subjectsLabel, and: subjectsTextField),
            createStackView(with: hourlyRateLabel, and: hourlyRateTextField),
            createStackView(with: introLabel, and: introTextView),
            saveButton
        ])
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .clear
           scrollView.translatesAutoresizingMaskIntoConstraints = false
           view.addSubview(scrollView)
           
           // Container View to hold profileImageView and stackView
           let containerView = UIView()
           containerView.translatesAutoresizingMaskIntoConstraints = false
           scrollView.addSubview(containerView)
           
           containerView.addSubview(profileImageView)
           containerView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
                // Scroll View
                scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                
                // Container View
                containerView.topAnchor.constraint(equalTo: scrollView.topAnchor),
                containerView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
                containerView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
                containerView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
                containerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
                
                // Profile Image View
                profileImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
                profileImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                profileImageView.heightAnchor.constraint(equalToConstant: 100),
                profileImageView.widthAnchor.constraint(equalToConstant: 100),
                
                // Stack View
                stackView.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 20),
                stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
                stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
                stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20)
            ])
    }
    
    private func createStackView(with label: UILabel, and inputView: UIView) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: [label, inputView])
        stackView.axis = .vertical
        stackView.spacing = 10
        return stackView
    }
    
    @objc func uploadImageButtonTapped() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
    
    // UIImagePickerControllerDelegate methods
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        if let editedImage = info[.editedImage] as? UIImage {
            profileImageView.image = editedImage
        } else if let originalImage = info[.originalImage] as? UIImage {
            profileImageView.image = originalImage
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    @objc func saveChanges() {
            guard let userID = userID else {
                print("Error: User not logged in.")
                return
            }
            
            // 開始加載動畫
            startSaveButtonAnimation()
            
            let db = Firestore.firestore()
            let teacherRef = db.collection("teachers").document(userID)
            
            let resumeData = [
                educationTextField.text ?? "",
                experienceTextField.text ?? "",
                introTextView.text ?? "",
                subjectsTextField.text ?? "",
                hourlyRateTextField.text ?? ""
            ]
            
        if profileImageView.image == UIImage(systemName: "person.crop.circle.badge.plus") {
                // 沒有上傳圖片，直接保存資料
                saveResumeData(teacherRef: teacherRef, resumeData: resumeData, profileImageURL: "") {
                    self.stopSaveButtonAnimation()
                    self.navigateToMainApp()
                }
            } else if let profileImage = profileImageView.image {
                uploadProfileImage(profileImage) { [weak self] result in
                    switch result {
                    case .success(let urlString):
                        self?.saveResumeData(teacherRef: teacherRef, resumeData: resumeData, profileImageURL: urlString) {
                            self?.stopSaveButtonAnimation()
                            self?.navigateToMainApp()
                        }
                    case .failure(let error):
                        self?.stopSaveButtonAnimation()
                        print("Error uploading profile image: \(error.localizedDescription)")
                    }
                }
            } else {
                // 如果沒有圖片，直接保存資料
                saveResumeData(teacherRef: teacherRef, resumeData: resumeData, profileImageURL: "") {
                    self.stopSaveButtonAnimation()
                    self.navigateToMainApp()
                }
            }
        }
        
        private func startSaveButtonAnimation() {
//            saveButton.setTitle("保存中", for: .normal)
            saveButton.setImage(UIImage(systemName: "ellipsis"), for: .normal)
            saveButton.semanticContentAttribute = .forceRightToLeft
            saveButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: -8)

            saveButton.imageView?.addSymbolEffect(.variableColor.iterative.nonReversing)
            
        }
        
        private func stopSaveButtonAnimation() {
            saveButton.imageView?.removeSymbolEffect(ofType: .variableColor)
            saveButton.setTitle("保存", for: .normal) // 恢復按鈕的標題
        }

    private func saveResumeData(teacherRef: DocumentReference, resumeData: [String], profileImageURL: String?, completion: @escaping () -> Void) {
        var dataToSave: [String: Any] = [
            "resume": resumeData
        ]
        
        if let profileImageURL = profileImageURL {
            dataToSave["photoURL"] = profileImageURL
        }
        
        teacherRef.updateData(dataToSave) { error in
            if let error = error {
                if (error as NSError).code == FirestoreErrorCode.notFound.rawValue {
                    teacherRef.setData([
                        "resume": resumeData,
                        "photoURL": profileImageURL ?? "",
                        "totalCourseHours": 0,
                        "timeSlots": []
                    ]) { error in
                        if let error = error {
                            print("Error creating data: \(error.localizedDescription)")
                        } else {
                            print("Data successfully created and saved.")
                            completion()
                        }
                    }
                } else {
                    print("Error updating data: \(error.localizedDescription)")
                }
            } else {
                print("Data successfully updated.")
                completion()
            }
        }
    }
    
    private func uploadProfileImage(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let userID = userID else { return }
        
        let storageRef = Storage.storage().reference().child("profile_images/\(userID).jpg")
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Error converting image to data.")
            return
        }
        
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let urlString = url?.absoluteString else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "URL not found"])))
                    return
                }
                
                completion(.success(urlString))
            }
        }
        
        profileImageView.contentMode = .scaleAspectFill
    }
    
    private func navigateToMainApp() {
        let userRole = UserDefaults.standard.string(forKey: "userRole") ?? "teacher"
        let mainVC = TabBarController(userRole: userRole)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = mainVC
            window.makeKeyAndVisible()
        }
    }
}
