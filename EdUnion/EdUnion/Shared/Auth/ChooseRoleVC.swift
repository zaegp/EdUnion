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
        button.setTitle("家教", for: .normal)
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
//        setupBackground()
        setupUI()
    }
    
//    private func setupBackground() {
//        let backgroundView = UIHostingController(rootView: GradientBackgroundView())
//        addChild(backgroundView)
//        backgroundView.view.frame = view.bounds
//        backgroundView.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        view.addSubview(backgroundView.view)
//        backgroundView.didMove(toParent: self)
//    }
    
    private func setupUI() {
        // Stack View for Buttons
        let buttonStackView = UIStackView(arrangedSubviews: [studentButton, tutorButton])
        buttonStackView.axis = .horizontal
        buttonStackView.spacing = 20
        buttonStackView.distribution = .fillEqually
        
        // Main Stack View
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

//struct GradientBackgroundView: View {
//    var body: some View {
//        LinearGradient(gradient: Gradient(colors: [Color(hex: "#E63C3A"), Color(hex: "#D6D4CE")]),
//                       startPoint: .top,
//                       endPoint: .bottom)
//        .edgesIgnoringSafeArea(.all)
//    }
//}
//
//struct ContentsView_Previews: PreviewProvider {
//    static var previews: some View {
//        GradientBackgroundView()
//    }
//}
