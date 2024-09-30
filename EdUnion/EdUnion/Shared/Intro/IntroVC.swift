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
    let uploadImageButton = UIButton(type: .system)
    
    let educationLabel = UILabel()
    let educationTextField = UITextField()
    
    let experienceLabel = UILabel()
    let experienceTextField = UITextField()
    
    let introLabel = UILabel()
    let introTextView = UITextView()
    
    let subjectsLabel = UILabel()
    let subjectsTextField = UITextField()
    
    let hourlyRateLabel = UILabel()
    let hourlyRateTextField = UITextField()
    
    let saveButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        setupKeyboardDismissRecognizer()
    }
    
    func setupUI() {
        // Configure profile image view
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 50
        profileImageView.clipsToBounds = true
        profileImageView.layer.borderWidth = 1
        profileImageView.layer.borderColor = UIColor.gray.cgColor
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 100).isActive = true
        
        // Configure upload button
        uploadImageButton.setTitle("Upload Profile Picture", for: .normal)
        uploadImageButton.addTarget(self, action: #selector(uploadImageButtonTapped), for: .touchUpInside)
        uploadImageButton.translatesAutoresizingMaskIntoConstraints = false
        
        educationLabel.text = "學歷"
        experienceLabel.text = "教學經驗"
        introLabel.text = "自我介紹"
        subjectsLabel.text = "教學科目"
        hourlyRateLabel.text = "時薪"
        
        for textField in [educationTextField, experienceTextField, subjectsTextField, hourlyRateTextField] {
            textField.borderStyle = .roundedRect
            textField.translatesAutoresizingMaskIntoConstraints = false
        }
        
        introTextView.layer.borderColor = UIColor.gray.cgColor
        introTextView.layer.borderWidth = 1.0
        introTextView.layer.cornerRadius = 8.0
        introTextView.font = UIFont.systemFont(ofSize: 16)
        introTextView.translatesAutoresizingMaskIntoConstraints = false
        introTextView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
        saveButton.setTitle("送出", for: .normal)
        saveButton.addTarget(self, action: #selector(saveChanges), for: .touchUpInside)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        
        let stackView = UIStackView(arrangedSubviews: [
            profileImageView,
            uploadImageButton,
            createStackView(with: educationLabel, and: educationTextField),
            createStackView(with: experienceLabel, and: experienceTextField),
            createStackView(with: introLabel, and: introTextView),
            createStackView(with: subjectsLabel, and: subjectsTextField),
            createStackView(with: hourlyRateLabel, and: hourlyRateTextField),
            saveButton
        ])
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stackView)
        
        // Set constraints
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func createStackView(with label: UILabel, and inputView: UIView) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: [label, inputView])
        stackView.axis = .vertical
        stackView.spacing = 5
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
        
        let db = Firestore.firestore()
        let teacherRef = db.collection("teachers").document(userID)
        
        let resumeData = [
            educationTextField.text ?? "",
            experienceTextField.text ?? "",
            introTextView.text ?? "",
            subjectsTextField.text ?? "",
            hourlyRateTextField.text ?? ""
        ]
        
        // Handle profile image upload if available
        if let profileImage = profileImageView.image {
            uploadProfileImage(profileImage) { [weak self] result in
                switch result {
                case .success(let urlString):
                    self?.saveResumeData(teacherRef: teacherRef, resumeData: resumeData, profileImageURL: urlString)
                case .failure(let error):
                    print("Error uploading profile image: \(error.localizedDescription)")
                }
            }
        } else {
            saveResumeData(teacherRef: teacherRef, resumeData: resumeData, profileImageURL: nil)
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
    }
    
    private func saveResumeData(teacherRef: DocumentReference, resumeData: [String], profileImageURL: String?) {
        var dataToSave: [String: Any] = [
            "resume": resumeData
        ]
        
        if let profileImageURL = profileImageURL {
            dataToSave["profileImageURL"] = profileImageURL
        }
        
        teacherRef.updateData(dataToSave) { error in
            if let error = error {
                if (error as NSError).code == FirestoreErrorCode.notFound.rawValue {
                    teacherRef.setData([
                        "resume": resumeData,
                        "profileImageURL": profileImageURL ?? "",
                        "totalCourseHours": 0,
                        "timeSlots": []
                    ]) { error in
                        if let error = error {
                            print("Error creating data: \(error.localizedDescription)")
                        } else {
                            print("Data successfully created and saved.")
                            self.navigateToMainApp()
                        }
                    }
                } else {
                    print("Error updating data: \(error.localizedDescription)")
                }
            } else {
                print("Data successfully updated.")
                self.navigateToMainApp()
            }
        }
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
