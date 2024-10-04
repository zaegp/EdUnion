//
//  TeacherCell.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/14.
//

import UIKit
import Kingfisher

//class TeacherCell: UICollectionViewCell {
//    
//    let image = UIImageView()
//    let nameLabel = UILabel()
//    let totalCoursesLabel = UILabel()
//    let subjectLabel = UILabel()
//    let educationLabel = UILabel()
//    let experienceLabel = UILabel()
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        
//        setupViews()
//        setupConstraints()
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    private func setupViews() {
//        image.layer.cornerRadius = 40
//        image.clipsToBounds = true
//        image.contentMode = .scaleAspectFill
//        contentView.addSubview(image)
//        
//        nameLabel.textAlignment = .center
//        nameLabel.font = UIFont.boldSystemFont(ofSize: 16)
//        nameLabel.textColor = .myBlack
//        contentView.addSubview(nameLabel)
//        
//        totalCoursesLabel.textAlignment = .center
//        totalCoursesLabel.font = UIFont.systemFont(ofSize: 12)
//        totalCoursesLabel.textColor = .darkGray
//        contentView.addSubview(totalCoursesLabel)
//        
//        subjectLabel.numberOfLines = 0
//        subjectLabel.font = UIFont.systemFont(ofSize: 12)
//        subjectLabel.textColor = .myGray
//        subjectLabel.textAlignment = .center
//        contentView.addSubview(subjectLabel)
//        
//        educationLabel.numberOfLines = 0
//        educationLabel.font = UIFont.systemFont(ofSize: 12)
//        educationLabel.textColor = .myGray
//        educationLabel.textAlignment = .center
//        contentView.addSubview(educationLabel)
//        
//        experienceLabel.numberOfLines = 0
//        experienceLabel.font = UIFont.systemFont(ofSize: 12)
//        experienceLabel.textColor = .myGray
//        experienceLabel.textAlignment = .center
//        contentView.addSubview(experienceLabel)
//        
//        contentView.layer.cornerRadius = 12
//        contentView.layer.masksToBounds = true
//        
////        layer.shadowColor = UIColor.black.cgColor
////        layer.shadowOpacity = 0.1
////        layer.shadowOffset = CGSize(width: 0, height: 2)
////        layer.shadowRadius = 4
////        layer.masksToBounds = false
//    }
//    
//    private func setupConstraints() {
//        image.translatesAutoresizingMaskIntoConstraints = false
//        nameLabel.translatesAutoresizingMaskIntoConstraints = false
//        totalCoursesLabel.translatesAutoresizingMaskIntoConstraints = false
//        subjectLabel.translatesAutoresizingMaskIntoConstraints = false
//        educationLabel.translatesAutoresizingMaskIntoConstraints = false
//        experienceLabel.translatesAutoresizingMaskIntoConstraints = false
//        
//        NSLayoutConstraint.activate([
//            image.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
//            image.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
//            image.widthAnchor.constraint(equalToConstant: 80),
//            image.heightAnchor.constraint(equalToConstant: 80),
//            
//            nameLabel.topAnchor.constraint(equalTo: image.bottomAnchor, constant: 8),
//            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
//            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
//            
//            totalCoursesLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
//            totalCoursesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
//            totalCoursesLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
//            
//            subjectLabel.topAnchor.constraint(equalTo: totalCoursesLabel.bottomAnchor, constant: 8),
//            subjectLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
//            subjectLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
//            
//            educationLabel.topAnchor.constraint(equalTo: subjectLabel.bottomAnchor, constant: 8),
//            educationLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
//            educationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
//            
//            experienceLabel.topAnchor.constraint(equalTo: educationLabel.bottomAnchor, constant: 8),
//            experienceLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
//            experienceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
//            experienceLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -16)
//        ])
//    }
//    
//    func configure(with teacher: Teacher) {
//        if let photoURL = teacher.photoURL, let url = URL(string: photoURL) {
//            image.kf.setImage(with: url, completionHandler: { [weak self] _ in
//                self?.setNeedsLayout()
//                self?.layoutIfNeeded()
//            })
//        } else {
//            image.image = UIImage(systemName: "person.crop.circle.fill")
//            image.tintColor = .myMessageCell
//        }
//        
//        nameLabel.text = teacher.fullName
//        totalCoursesLabel.text = "已在平台上 \(teacher.totalCourses) 節課"
//        subjectLabel.text = "教學科目: \(teacher.resume[3])"
//        
//        educationLabel.text = "學歷: \(teacher.resume[0])"
//        experienceLabel.text = "家教經驗: \(teacher.resume[1])"
//    }
//}

class TeacherCell: UICollectionViewCell {
    
    let image = UIImageView()
    let nameLabel = UILabel()
    let totalCoursesLabel = UILabel()
    let subjectLabel = UILabel()
    let educationLabel = UILabel()
    let experienceLabel = UILabel()
    private let stackView = UIStackView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        // 設置圖片
        image.layer.cornerRadius = 40
        image.clipsToBounds = true
        image.contentMode = .scaleAspectFill
        image.translatesAutoresizingMaskIntoConstraints = false
        
        [nameLabel, totalCoursesLabel, subjectLabel, educationLabel, experienceLabel].forEach {
            $0.textAlignment = .center
            $0.numberOfLines = 0
            $0.font = UIFont.systemFont(ofSize: 12)
        }
        nameLabel.font = UIFont.boldSystemFont(ofSize: 16)
        nameLabel.textColor = .myMessageCell
        totalCoursesLabel.textColor = .myMessageCell
        subjectLabel.textColor = .myMessageCell
        educationLabel.textColor = .myMessageCell
        experienceLabel.textColor = .myMessageCell
        
        // 設置 StackView
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加圖片和標籤到 StackView
        stackView.addArrangedSubview(image)
        stackView.addArrangedSubview(nameLabel)
        stackView.addArrangedSubview(subjectLabel)
        stackView.addArrangedSubview(educationLabel)
        stackView.addArrangedSubview(experienceLabel)
        stackView.addArrangedSubview(totalCoursesLabel)
        
        contentView.addSubview(stackView)
        
        // 設置 cell 的外觀
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true
    }
    
    private func setupConstraints() {
        // 設置 StackView 約束
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -16)
        ])
        
        // 設置圖片大小約束
        NSLayoutConstraint.activate([
            image.widthAnchor.constraint(equalToConstant: 80),
            image.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    func configure(with teacher: Teacher) {
        if let photoURL = teacher.photoURL, let url = URL(string: photoURL) {
            image.kf.setImage(with: url, completionHandler: { [weak self] _ in
                self?.setNeedsLayout()
                self?.layoutIfNeeded()
            })
        } else {
            image.image = UIImage(systemName: "person.crop.circle.fill")
            image.tintColor = .myMessageCell
        }
        
        nameLabel.text = teacher.fullName
        totalCoursesLabel.text = "已在平台上 \(teacher.totalCourses) 節課"
        subjectLabel.text = "教學科目: \(teacher.resume[3])"
        educationLabel.text = "學歷: \(teacher.resume[0])"
        experienceLabel.text = "家教經驗: \(teacher.resume[1])"
    }
}
