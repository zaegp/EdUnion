//
//  ChooseRoleVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/26.
//

import SwiftUI
import UIKit

var teacherID = "001"

class ChooseRoleVC: UIViewController {
    
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
        button.addTarget(self, action: #selector(didTapTeacher), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBackground()
        setupButtons()
    }
    
    private func setupBackground() {
        let backgroundView = UIHostingController(rootView: GradientBackgroundView())
        addChild(backgroundView)
        backgroundView.view.frame = view.bounds
        backgroundView.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(backgroundView.view)
        backgroundView.didMove(toParent: self)
    }
    
    private func setupButtons() {
        view.addSubview(studentButton)
        view.addSubview(tutorButton)
        
        studentButton.translatesAutoresizingMaskIntoConstraints = false
        tutorButton.translatesAutoresizingMaskIntoConstraints = false
        
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
        LinearGradient(gradient: Gradient(colors: [Color(hex: "#fca311"), Color(hex: "#14213d")]),
                       startPoint: .top,
                       endPoint: .bottom)
        .edgesIgnoringSafeArea(.all)
    }
}

struct RadialGradientView: View {
    var body: some View {
        RadialGradient(
            gradient: Gradient(colors: [Color(hex: "#fca311"), Color(hex: "#000000")]),
            center: .bottom, // 漸變的中心
            startRadius: 20, // 漸變開始的半徑
            endRadius: 300   // 漸變結束的半徑
        )
        .edgesIgnoringSafeArea(.all)
    }
}
struct ContentsView_Previews: PreviewProvider {
    static var previews: some View {
        RadialGradientView()
    }
}
