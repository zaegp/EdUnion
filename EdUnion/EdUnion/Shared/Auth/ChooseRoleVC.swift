//
//  ChooseRoleVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/26.
//

import SwiftUI
import UIKit

class ChooseRoleVC: UIViewController {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "你的身份是...?"
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()
    
    private let studentButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("學生", for: .normal)
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.myGray.cgColor
        button.setTitleColor(.label, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        button.layer.cornerRadius = 5
        button.addTarget(self, action: #selector(didTapStudent), for: .touchUpInside)
        return button
    }()
    
    private let tutorButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("老師", for: .normal)
        button.layer.borderWidth = 1
        button.setTitleColor(.label, for: .normal)
        button.layer.borderColor = UIColor.myGray.cgColor
        button.setTitleColor(.label, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        button.layer.cornerRadius = 5
        button.addTarget(self, action: #selector(didTapTeacher), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .myBackground
        setupUI()
    }
    
    private func setupUI() {
        let buttonStackView = UIStackView(arrangedSubviews: [studentButton, tutorButton])
        buttonStackView.axis = .horizontal
        buttonStackView.spacing = 20
        buttonStackView.distribution = .fillEqually
        
        let mainStackView = UIStackView(arrangedSubviews: [titleLabel, buttonStackView])
        mainStackView.axis = .vertical
        mainStackView.spacing = 40
        mainStackView.alignment = .center
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(mainStackView)
        
        NSLayoutConstraint.activate([
            mainStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mainStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            buttonStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            buttonStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            studentButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func didTapStudent() {
        UserDefaults.standard.set("student", forKey: "userRole")
        navigateToAuthApp()
    }
    
    @objc private func didTapTeacher() {
        UserDefaults.standard.set("teacher", forKey: "userRole")
        navigateToAuthApp()
    }
    
    private func navigateToAuthApp() {
        let authView = AuthenticationView()
        let hostingController = UIHostingController(rootView: authView)
        hostingController.modalPresentationStyle = .fullScreen 

        present(hostingController, animated: true, completion: nil)
    }
}
