//
//  ResumeVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/18.
//

import UIKit
import FirebaseFirestore

class ResumeVC: UIViewController {
    
    let label1 = UILabel()
    let textField1 = PaddedTextField()
    
    let label2 = UILabel()
    let textField2 = PaddedTextField()
    
    let label3 = UILabel()
    let textView3 = UITextView()
    
    let label4 = UILabel()
    let textField4 = PaddedTextField()
    
    let label5 = UILabel()
    let textField5 = PaddedTextField()
    
    let saveButton = UIButton(type: .system)
    
    let userID = UserSession.shared.currentUserID
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .myBackground
        
        setupUI()
        fetchResumeData()
        setupKeyboardDismissRecognizer()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let tabBarController = self.tabBarController as? TabBarController {
            tabBarController.setCustomTabBarHidden(true, animated: true)
        }
    }
    
    func setupUI() {

        configureLabels()
        configureTextFields()
        configureTextView()
        configureSaveButton()
        
        let stackViews = createStackViews()
        let mainStackView = UIStackView(arrangedSubviews: stackViews + [saveButton])
        mainStackView.axis = .vertical
        mainStackView.spacing = 20
        
        view.addSubview(mainStackView)
        
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            mainStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mainStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            mainStackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            mainStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            mainStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func configureLabels() {
        let labels = [label1, label2, label3, label5, label4]
        let labelTexts = ["- 學歷 -", "- 家教經驗 -", "- 教學科目 -", "- 時薪 -", "- 自我介紹 -"]
        
        for (label, text) in zip(labels, labelTexts) {
            label.text = text
            label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            label.textAlignment = .center
        }
    }
    
    private func configureTextFields() {
        let textFields = [textField1, textField2, textField4, textField5]
        
        for textField in textFields {
            textField.borderStyle = .none
            textField.textColor = .black
            textField.layer.cornerRadius = 10
//            textField.layer.borderWidth = 1
//            textField.layer.borderColor = UIColor.mainTint.cgColor
            textField.clipsToBounds = true
            textField.backgroundColor = .myGray
            textField.textAlignment = .left
            textField.horizontalPadding = 10
            textField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        }
    }
    
    private func configureTextView() {
        textView3.layer.cornerRadius = 20
        textView3.backgroundColor = .myGray
        textView3.font = UIFont.systemFont(ofSize: 16)
        textView3.isScrollEnabled = true
        textView3.contentInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        textView3.heightAnchor.constraint(equalToConstant: 160).isActive = true
    }
    
    private func configureSaveButton() {
        saveButton.setTitle("保存", for: .normal)
        saveButton.backgroundColor = .mainOrange
        saveButton.tintColor = .white
        saveButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        saveButton.layer.cornerRadius = 30
        saveButton.heightAnchor.constraint(equalToConstant: 60).isActive = true
        saveButton.addTarget(self, action: #selector(saveChanges), for: .touchUpInside)
    }
    
    private func createStackViews() -> [UIStackView] {
        let stackView1 = createStackView(with: label1, textField: textField1)
        let stackView2 = createStackView(with: label2, textField: textField2)
        let stackView3 = createStackView(with: label4, textView: textView3)
        let stackView4 = createStackView(with: label3, textField: textField4)
        let stackView5 = createStackView(with: label5, textField: textField5)
        
        return [stackView1, stackView2, stackView4, stackView5, stackView3]
    }
    
    private func createStackView(with label: UILabel, textField: UITextField) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: [label, textField])
        stackView.axis = .vertical
        stackView.spacing = 10
        return stackView
    }
    
    private func createStackView(with label: UILabel, textView: UITextView) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: [label, textView])
        stackView.axis = .vertical
        stackView.spacing = 10
        return stackView
    }
    
    func fetchResumeData() {
        let db = Firestore.firestore()
        let teacherRef = db.collection("teachers").document(userID ?? "")
        
        teacherRef.getDocument { [weak self] (document, error) in
            if let error = error {
                print("獲取數據失敗: \(error)")
                return
            }
            
            if let document = document, document.exists {
                if let resume = document.data()?["resume"] as? [String], resume.count >= 5 {
                    self?.textField1.text = resume[0]
                    self?.textField2.text = resume[1]
                    self?.textView3.text = resume[2]
                    self?.textField4.text = resume[3]
                    self?.textField5.text = resume[4]
                }
            }
        }
    }
    
    @objc func saveChanges() {
        let db = Firestore.firestore()
        let teacherRef = db.collection("teachers").document(userID ?? "")
        
        let updatedResume = [
            textField1.text ?? "",
            textField2.text ?? "",
            textView3.text ?? "",
            textField4.text ?? "",
            textField5.text ?? ""
        ]
        
        teacherRef.updateData([
            "resume": updatedResume
        ]) { error in
            if let error = error {
                print("更新數據失敗: \(error)")
            } else {
                print("數據已更新成功")
            }
        }
        
        navigationController?.popViewController(animated: true)
    }
}
