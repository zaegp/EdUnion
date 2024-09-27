//
//  IntroVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/26.
//

import UIKit
import FirebaseFirestore

class IntroVC: UIViewController {
    let userID = UserSession.shared.currentUserID
    
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
    
    // 設定 UI
    func setupUI() {
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
        
        // 設置約束
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    // 創建 StackView
    private func createStackView(with label: UILabel, and inputView: UIView) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: [label, inputView])
        stackView.axis = .vertical
        stackView.spacing = 5
        return stackView
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
        
        teacherRef.updateData(["resume": resumeData]) { error in
            if let error = error {
                if (error as NSError).code == FirestoreErrorCode.notFound.rawValue {
                    teacherRef.setData([
                        "resume": resumeData,
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
