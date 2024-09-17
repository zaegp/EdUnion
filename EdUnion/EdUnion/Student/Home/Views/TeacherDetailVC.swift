//
//  TeacherDetailVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/14.
//

import UIKit

class TeacherDetailVC: UIViewController {
    
    var teacher: Teacher?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        title = teacher?.name ?? "Teacher Detail"
        
        setupUI()
    }
    
    private func setupUI() {
        guard let teacher = teacher else { return }
        
        let nameLabel = UILabel()
        nameLabel.text = teacher.name
        nameLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nameLabel)
        
        let bookButton = UIButton(type: .system)
        bookButton.setTitle("預約", for: .normal)
        bookButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        bookButton.backgroundColor = .systemBlue
        bookButton.setTitleColor(.white, for: .normal)
        bookButton.layer.cornerRadius = 10
        bookButton.translatesAutoresizingMaskIntoConstraints = false
        
        bookButton.addTarget(self, action: #selector(bookButtonTapped), for: .touchUpInside)
        

        view.addSubview(bookButton)
        
        NSLayoutConstraint.activate([
            nameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nameLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            
            bookButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bookButton.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 20),
            bookButton.widthAnchor.constraint(equalToConstant: 150),
            bookButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func bookButtonTapped() {
        let bookingVC = BookingVC()
        print("111111111")
        print(teacher)
        bookingVC.teacher = teacher
        navigationController?.pushViewController(bookingVC, animated: true)
    }
}
