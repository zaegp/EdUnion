//
//  ResumeVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/18.
//

import UIKit
import FirebaseFirestore

class ResumeVC: UIViewController {
    
    // 四個文本輸入框和對應的標籤
    let label1 = UILabel()
    let textField1 = UITextField()
    
    let label2 = UILabel()
    let textField2 = UITextField()
    
    let label3 = UILabel()
    let textView3 = UITextView()
    
    let label4 = UILabel()
    let textField4 = UITextField()
    
    let saveButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupUI()
        fetchResumeData()
    }
    
    // 設置 UI 布局
    func setupUI() {
            // 配置標籤內容
            label1.text = "學校"
            label2.text = "工作經驗"
            label3.text = "問候語"  // 這個將用來對應 UITextView
            label4.text = "首頁的一句話"
            
            // 配置文本框樣式
            for textField in [textField1, textField2, textField4] {
                textField.borderStyle = .roundedRect
            }
            
            // 配置 UITextView 樣式
            textView3.layer.borderColor = UIColor.gray.cgColor
            textView3.layer.borderWidth = 1.0
            textView3.layer.cornerRadius = 8.0
            textView3.font = UIFont.systemFont(ofSize: 16)
            textView3.isScrollEnabled = true
            textView3.heightAnchor.constraint(equalToConstant: 100).isActive = true // 設置高度
            
            // 配置保存按鈕
            saveButton.setTitle("保存更改", for: .normal)
            saveButton.addTarget(self, action: #selector(saveChanges), for: .touchUpInside)
            
            // 將標籤和文本框組合成垂直堆疊
            let stackView1 = UIStackView(arrangedSubviews: [label1, textField1])
            let stackView2 = UIStackView(arrangedSubviews: [label2, textField2])
            let stackView3 = UIStackView(arrangedSubviews: [label3, textView3]) // 這裡使用 UITextView
            let stackView4 = UIStackView(arrangedSubviews: [label4, textField4])
            
            // 設置每個 stackView 的屬性
            for stackView in [stackView1, stackView2, stackView3, stackView4] {
                stackView.axis = .vertical
                stackView.spacing = 5
            }
            
            // 最終將所有 stackView 和保存按鈕加入主 stackView
            let mainStackView = UIStackView(arrangedSubviews: [stackView1, stackView2, stackView3, stackView4, saveButton])
            mainStackView.axis = .vertical
            mainStackView.spacing = 20
            mainStackView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(mainStackView)
            
            // 設置主 stackView 的約束
            NSLayoutConstraint.activate([
                mainStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                mainStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                mainStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                mainStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
            ])
        }
    
    // 從 Firebase 獲取 resume 資料
    func fetchResumeData() {
        let db = Firestore.firestore()
        let teacherRef = db.collection("teachers").document(teacherID)
        
        teacherRef.getDocument { (document, error) in
            if let error = error {
                print("獲取數據失敗: \(error)")
                return
            }
            
            if let document = document, document.exists {
                if let resume = document.data()?["resume"] as? [String] {
                    // 設置文本框初始值
                    if resume.count >= 4 {
                        self.textField1.text = resume[0]
                        self.textField2.text = resume[1]
                        self.textView3.text = resume[2]
                        self.textField4.text = resume[3]
                    }
                }
            }
        }
    }
    
    // 保存更改到 Firebase
    @objc func saveChanges() {
        let db = Firestore.firestore()
        let teacherRef = db.collection("teachers").document(teacherID)
        
        // 取得使用者輸入的資料
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
