//
//  ChooseRoleVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/26.
//

import SwiftUI
import UIKit

//var teacherID = "001"

class ChooseRoleVC: UIViewController {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "你的身份是...?"
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()
    
    private let studentButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("學生", for: .normal)
        button.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.00)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        button.layer.cornerRadius = 5
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
        button.addTarget(self, action: #selector(didTapTeacher), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBackground()
        setupUI()
    }
    
    private func setupBackground() {
        let backgroundView = UIHostingController(rootView: GradientBackgroundView())
        addChild(backgroundView)
        backgroundView.view.frame = view.bounds
        backgroundView.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(backgroundView.view)
        backgroundView.didMove(toParent: self)
    }
    
    private func setupUI() {
        view.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let buttonStackView = UIStackView(arrangedSubviews: [studentButton, tutorButton])
        buttonStackView.axis = .horizontal
        buttonStackView.spacing = 20
        buttonStackView.distribution = .fillEqually
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(buttonStackView)
        
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            
            buttonStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buttonStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
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
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = hostingController
            window.makeKeyAndVisible()
        }
    }
}

struct GradientBackgroundView: View {
    var body: some View {
        LinearGradient(gradient: Gradient(colors: [Color(hex: "#eeeeee"), Color(hex: "#ff6347"), Color(hex: "#252525")]),
                       startPoint: .top,
                       endPoint: .bottom)
        .edgesIgnoringSafeArea(.all)
    }
}

struct ContentsView_Previews: PreviewProvider {
    static var previews: some View {
        RadialGradientView()
    }
}
