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
    let textField1 = UITextField()
    
    let label2 = UILabel()
    let textField2 = UITextField()
    
    let label3 = UILabel()
    let textView3 = UITextView()
    
    let label4 = UILabel()
    let textField4 = UITextField()
    
    let saveButton = UIButton(type: .system)
    
    let userID = UserSession.shared.currentUserID

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupUI()
        fetchResumeData()
        setupKeyboardDismissRecognizer()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tabBarController?.tabBar.isHidden = true
        if let tabBarController = self.tabBarController as? TabBarController {
            tabBarController.setCustomTabBarHidden(true, animated: true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let tabBarController = self.tabBarController as? TabBarController {
            tabBarController.setCustomTabBarHidden(false, animated: true)
        }
    }
    
    func setupUI() {
        label1.text = "學歷"
        label2.text = "家教經驗"
        label3.text = "教學科目"
        label4.text = "自我介紹"
        
        for textField in [textField1, textField2, textField4] {
            textField.borderStyle = .roundedRect
        }
        
        textView3.layer.borderColor = UIColor.gray.cgColor
        textView3.layer.borderWidth = 1.0
        textView3.layer.cornerRadius = 8.0
        textView3.font = UIFont.systemFont(ofSize: 16)
        textView3.isScrollEnabled = true
        textView3.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
        saveButton.setTitle("保存更改", for: .normal)
        saveButton.addTarget(self, action: #selector(saveChanges), for: .touchUpInside)
        
        let stackView1 = UIStackView(arrangedSubviews: [label1, textField1])
        let stackView2 = UIStackView(arrangedSubviews: [label2, textField2])
        let stackView3 = UIStackView(arrangedSubviews: [label4, textView3])
        let stackView4 = UIStackView(arrangedSubviews: [label3, textField4])
        
        for stackView in [stackView1, stackView2, stackView3, stackView4] {
            stackView.axis = .vertical
            stackView.spacing = 5
        }
        
        let mainStackView = UIStackView(arrangedSubviews: [stackView1, stackView2, stackView4, stackView3, saveButton])
        mainStackView.axis = .vertical
        mainStackView.spacing = 20
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainStackView)
        
        NSLayoutConstraint.activate([
            mainStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mainStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            mainStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    func fetchResumeData() {
        let db = Firestore.firestore()
        let teacherRef = db.collection("teachers").document(userID ?? "")
        
        teacherRef.getDocument { (document, error) in
            if let error = error {
                print("獲取數據失敗: \(error)")
                return
            }
            
            if let document = document, document.exists {
                if let resume = document.data()?["resume"] as? [String] {
                    self.textField1.text = resume[0]
                    self.textField2.text = resume[1]
                    self.textView3.text = resume[2]
                    self.textField4.text = resume[3]
                    
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
            textField4.text ?? ""
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
    }
}
