//
//  ChooseRoleVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/26.
//

import UIKit
import SwiftUI

class ChooseRoleVC: UIViewController {
    
    // 創建兩個按鈕分別供學生和家教選擇
    private let studentButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("學生", for: .normal)
        button.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.00)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        button.layer.cornerRadius = 5
        button.frame = CGRect(x: 0, y: 0, width: 250, height: 50)
        button.addTarget(self, action: #selector(didTapStudent), for: .touchUpInside)
        return button
    }()
    
    private let tutorButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("家教", for: .normal)
        button.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.00)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        button.layer.cornerRadius = 5
        button.frame = CGRect(x: 0, y: 0, width: 250, height: 50)
        button.addTarget(self, action: #selector(didTapTutor), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupButtons()
    }
    
    private func setupButtons() {
        // 設定按鈕的佈局
        view.addSubview(studentButton)
        view.addSubview(tutorButton)
        
        studentButton.translatesAutoresizingMaskIntoConstraints = false
        tutorButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 設置按鈕佈局
        NSLayoutConstraint.activate([
            studentButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            studentButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30),
            studentButton.widthAnchor.constraint(equalToConstant: 200),
            studentButton.heightAnchor.constraint(equalToConstant: 50),
            
            tutorButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            tutorButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 50),
            tutorButton.widthAnchor.constraint(equalToConstant: 200),
            tutorButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func didTapStudent() {
        UserDefaults.standard.set("student", forKey: "userRole")
        navigateToAuthApp()
    }
    
    @objc private func didTapTutor() {
        UserDefaults.standard.set("teacher", forKey: "userRole")
        navigateToAuthApp()
    }
    
    private func navigateToAuthApp() {
        let authView = AuthenticationView()
        
        let hostingController = UIHostingController(rootView: authView)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = hostingController
            window.makeKeyAndVisible()
        }
    }
}
