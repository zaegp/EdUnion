//
//  TeacherCell.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/14.
//

import UIKit
import Kingfisher

class TeacherCell: UICollectionViewCell {
    
    private let image = UIImageView()
    private let nameLabel = UILabel()
    private let totalCoursesLabel = UILabel()
    private let subjectLabel = UILabel()
    private let educationLabel = UILabel() 
    private let experienceLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        image.layer.cornerRadius = 40
        image.clipsToBounds = true
        image.contentMode = .scaleAspectFill
        /*image.backgroundColor = .lightGray*/  // 預設背景顏色以防圖片加載失敗
        contentView.addSubview(image)
        
        nameLabel.textAlignment = .center
        nameLabel.font = UIFont.boldSystemFont(ofSize: 16)
        nameLabel.textColor = .black
        contentView.addSubview(nameLabel)
        
        totalCoursesLabel.textAlignment = .center
        totalCoursesLabel.font = UIFont.systemFont(ofSize: 14)
        totalCoursesLabel.textColor = .darkGray
        contentView.addSubview(totalCoursesLabel)
        
        subjectLabel.numberOfLines = 0
        subjectLabel.font = UIFont.systemFont(ofSize: 12)
        subjectLabel.textColor = .gray
        subjectLabel.textAlignment = .center
        contentView.addSubview(subjectLabel)
        
        educationLabel.numberOfLines = 0
        educationLabel.font = UIFont.systemFont(ofSize: 12)
        educationLabel.textColor = .darkGray
        educationLabel.textAlignment = .center
        contentView.addSubview(educationLabel)
        
        experienceLabel.numberOfLines = 0
        experienceLabel.font = UIFont.systemFont(ofSize: 12)
        experienceLabel.textColor = .darkGray
        experienceLabel.textAlignment = .center
        contentView.addSubview(experienceLabel)
        
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true
        
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        layer.masksToBounds = false
    }
    
    private func setupConstraints() {
        image.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        totalCoursesLabel.translatesAutoresizingMaskIntoConstraints = false
        subjectLabel.translatesAutoresizingMaskIntoConstraints = false
        educationLabel.translatesAutoresizingMaskIntoConstraints = false
        experienceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            image.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            image.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            image.widthAnchor.constraint(equalToConstant: 80),
            image.heightAnchor.constraint(equalToConstant: 80),
            
            nameLabel.topAnchor.constraint(equalTo: image.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            totalCoursesLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            totalCoursesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            totalCoursesLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            subjectLabel.topAnchor.constraint(equalTo: totalCoursesLabel.bottomAnchor, constant: 8),
            subjectLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            subjectLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            educationLabel.topAnchor.constraint(equalTo: subjectLabel.bottomAnchor, constant: 8),
            educationLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            educationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            experienceLabel.topAnchor.constraint(equalTo: educationLabel.bottomAnchor, constant: 8),
            experienceLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            experienceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            experienceLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    func configure(with teacher: Teacher) {
        if let photoURL = teacher.photoURL, let url = URL(string: photoURL) {
            image.kf.setImage(with: url)
        } else {
            image.image = UIImage(systemName: "face.smiling.inverse")
            image.tintColor = .mainOrange
        }
        
        nameLabel.text = teacher.name
        totalCoursesLabel.text = "總課程數量: \(teacher.totalCourses)"
        subjectLabel.text = teacher.resume[3]
        
        educationLabel.text = "學歷: \(teacher.resume[0])"
        experienceLabel.text = "家教經驗: \(teacher.resume[1])"
    }
}
