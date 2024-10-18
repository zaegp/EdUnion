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
    let userID = UserSession.shared.unwrappedUserID

    let profileImageView = UIImageView()

    let nameLabel = UILabel()
    let nameTextField = PaddedTextField()

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

    let userRole = UserDefaults.standard.string(forKey: "userRole") ?? "teacher"

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
        configureProfileImageView()
        configureNameFields()
        configureOtherLabelsAndTextFields()
        configureSaveButton()
        setupScrollViewAndContainer()
    }

    private func configureProfileImageView() {
        profileImageView.image = UIImage(systemName: "person.crop.circle.badge.plus")
        profileImageView.tintColor = .myBlack
        profileImageView.contentMode = .scaleAspectFit
        profileImageView.layer.cornerRadius = 50
        profileImageView.clipsToBounds = true
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
    }

    private func configureNameFields() {
        nameLabel.text = "- 名字 -"
        nameLabel.textAlignment = .center
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.minimumScaleFactor = 0.5
        
        nameTextField.borderStyle = .none
        nameTextField.layer.cornerRadius = 10
        nameTextField.layer.borderWidth = 1
        nameTextField.layer.borderColor = UIColor.myGray.cgColor
        nameTextField.clipsToBounds = true
        nameTextField.backgroundColor = .systemBackground
        nameTextField.textAlignment = .left
        nameTextField.horizontalPadding = 10
        nameTextField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        nameTextField.tintColor = .mainOrange
        
        nameTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        if textField == nameTextField {
            let isNameEmpty = nameTextField.text?.isEmpty ?? true
            saveButton.isEnabled = !isNameEmpty
        }
    }

    private func configureOtherLabelsAndTextFields() {
        educationLabel.text = "- 學歷 -"
        experienceLabel.text = "- 教學經驗 -"
        introLabel.text = "- 自我介紹 -"
        subjectsLabel.text = "- 教學科目 -"
        hourlyRateLabel.text = "- 時薪 -"
        
        let labels = [educationLabel, experienceLabel, introLabel, subjectsLabel, hourlyRateLabel]
        for label in labels {
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.5
        }

        let textFields = [educationTextField, experienceTextField, subjectsTextField, hourlyRateTextField]
        for textField in textFields {
            textField.borderStyle = .none
            textField.layer.cornerRadius = 10
            textField.layer.borderWidth = 1
            textField.layer.borderColor = UIColor.myGray.cgColor
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
    }

    private func configureSaveButton() {
        saveButton.setTitle("保存", for: .normal)
        saveButton.backgroundColor = .mainOrange
        saveButton.tintColor = .white
        saveButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        saveButton.layer.cornerRadius = 30
        saveButton.heightAnchor.constraint(equalToConstant: 60).isActive = true
        saveButton.addTarget(self, action: #selector(saveChanges), for: .touchUpInside)
        
        saveButton.isEnabled = false
    }

    private func setupScrollViewAndContainer() {
        let nameStackView = UIStackView(arrangedSubviews: [nameLabel, nameTextField])
        nameStackView.axis = .vertical
        nameStackView.spacing = 10

        let profileAndNameStackView = UIStackView(arrangedSubviews: [profileImageView, nameStackView])
        profileAndNameStackView.axis = .vertical
        profileAndNameStackView.spacing = 20
        profileAndNameStackView.alignment = .center
        profileAndNameStackView.translatesAutoresizingMaskIntoConstraints = false

        var contentArrangedSubviews: [UIView] = []

        if userRole == "teacher" {
            contentArrangedSubviews = [
                createStackView(with: educationLabel, and: educationTextField),
                createStackView(with: experienceLabel, and: experienceTextField),
                createStackView(with: subjectsLabel, and: subjectsTextField),
                createStackView(with: hourlyRateLabel, and: hourlyRateTextField),
                createStackView(with: introLabel, and: introTextView),
                saveButton
            ]
        } else if userRole == "student" {
            contentArrangedSubviews = [saveButton]
        }

        let stackView = UIStackView(arrangedSubviews: contentArrangedSubviews)
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let scrollView = UIScrollView()
        scrollView.backgroundColor = .clear
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(containerView)

        containerView.addSubview(profileAndNameStackView)
        containerView.addSubview(stackView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            containerView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            containerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            profileAndNameStackView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            profileAndNameStackView.topAnchor.constraint(equalTo: userRole == "student" ? containerView.centerYAnchor : containerView.topAnchor, constant: userRole == "student" ? -100 : 20),
            
            profileImageView.heightAnchor.constraint(equalToConstant: 100),
            profileImageView.widthAnchor.constraint(equalToConstant: 100),

            stackView.topAnchor.constraint(equalTo: profileAndNameStackView.bottomAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20)
        ])

        nameTextField.widthAnchor.constraint(equalTo: containerView.widthAnchor, constant: -40).isActive = true
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
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
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

        startSaveButtonAnimation()

        let db = Firestore.firestore()
        
        let collectionName = userRole == "teacher" ? "teachers" : "students"
        let userRef = db.collection(collectionName).document(userID)

        var resumeData: [String] = []
        if userRole == "teacher" {
            resumeData = [
                educationTextField.text ?? "",
                experienceTextField.text ?? "",
                introTextView.text ?? "",
                subjectsTextField.text ?? "",
                hourlyRateTextField.text ?? ""
            ]
        }

        let name = nameTextField.text ?? ""

        if profileImageView.image == UIImage(systemName: "person.crop.circle.badge.plus") {
            saveResumeData(userRef: userRef, resumeData: resumeData, name: name, profileImageURL: nil) {
                self.stopSaveButtonAnimation()
                self.navigateToMainApp()
            }
        } else if let profileImage = profileImageView.image {
            uploadProfileImage(profileImage) { [weak self] result in
                switch result {
                case .success(let urlString):
                    self?.saveResumeData(userRef: userRef, resumeData: resumeData, name: name, profileImageURL: urlString) {
                        self?.stopSaveButtonAnimation()
                        self?.navigateToMainApp()
                    }
                case .failure(let error):
                    self?.stopSaveButtonAnimation()
                    print("Error uploading profile image: \(error.localizedDescription)")
                }
            }
        } else {
            saveResumeData(userRef: userRef, resumeData: resumeData, name: name, profileImageURL: nil) {
                self.stopSaveButtonAnimation()
                self.navigateToMainApp()
            }
        }
    }
    
    private func startSaveButtonAnimation() {
        saveButton.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        saveButton.semanticContentAttribute = .forceRightToLeft
        saveButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: -8)
        saveButton.imageView?.addSymbolEffect(.variableColor.iterative.nonReversing)
    }

    private func stopSaveButtonAnimation() {
        saveButton.imageView?.removeSymbolEffect(ofType: .variableColor)
        saveButton.setTitle("保存", for: .normal)
    }

    private func saveResumeData(userRef: DocumentReference, resumeData: [String], name: String, profileImageURL: String?, completion: @escaping () -> Void) {
        var dataToSave: [String: Any] = [:]

        if userRole == "teacher" {
            dataToSave["resume"] = resumeData
        }

        dataToSave["fullName"] = name

        if let profileImageURL = profileImageURL {
            dataToSave["photoURL"] = profileImageURL
        }

        userRef.updateData(dataToSave) { error in
            if let error = error {
                if (error as NSError).code == FirestoreErrorCode.notFound.rawValue {
                    userRef.setData([
                        "resume": resumeData,
                        "photoURL": profileImageURL ?? "",
                        "fullName": name
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
                    completion() 
                }
            } else {
                print("Data successfully updated.")
                completion()
            }
        }
    }
    
    private func uploadProfileImage(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        let roleFolder = (userRole == "teacher") ? "teacher_images" : "student_images"
        let storageRef = Storage.storage().reference().child("\(roleFolder)/\(userID).jpg")

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
