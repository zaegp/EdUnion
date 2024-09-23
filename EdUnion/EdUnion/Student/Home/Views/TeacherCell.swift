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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        // 圖片設置圓角並裁剪多餘部分
        image.layer.cornerRadius = 40  // 假設圖片是正方形，40 是圓角半徑
        image.clipsToBounds = true
        image.contentMode = .scaleAspectFill
        image.backgroundColor = .lightGray  // 預設背景顏色以防圖片加載失敗
        contentView.addSubview(image)
        
        // 名字標籤
        nameLabel.textAlignment = .center
        nameLabel.font = UIFont.boldSystemFont(ofSize: 16)
        nameLabel.textColor = .black
        contentView.addSubview(nameLabel)
        
        // 總課程標籤
        totalCoursesLabel.textAlignment = .center
        totalCoursesLabel.font = UIFont.systemFont(ofSize: 14)
        totalCoursesLabel.textColor = .darkGray
        contentView.addSubview(totalCoursesLabel)
        
        // 簡歷標籤
        subjectLabel.numberOfLines = 0
        subjectLabel.font = UIFont.systemFont(ofSize: 12)
        subjectLabel.textColor = .gray
        subjectLabel.textAlignment = .center
        contentView.addSubview(subjectLabel)
        
        // 圓角設置
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true
        
        // 添加陰影效果
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
        
        NSLayoutConstraint.activate([
            // 設置圖片大小和位置
            image.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            image.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            image.widthAnchor.constraint(equalToConstant: 80),  // 固定圖片寬度
            image.heightAnchor.constraint(equalToConstant: 80), // 固定圖片高度
            
            // 名字標籤位置
            nameLabel.topAnchor.constraint(equalTo: image.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // 總課程標籤位置
            totalCoursesLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            totalCoursesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            totalCoursesLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // 簡歷標籤位置
            subjectLabel.topAnchor.constraint(equalTo: totalCoursesLabel.bottomAnchor, constant: 8),
            subjectLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            subjectLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            subjectLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -16)  
        ])
    }
    
    func configure(with teacher: Teacher) {
        if let photoURL = teacher.photoURL, let url = URL(string: photoURL) {
            image.kf.setImage(with: url)
        } else {
            image.image = UIImage(named: "placeholder")
        }
        
        nameLabel.text = teacher.name
        totalCoursesLabel.text = String(teacher.totalCourses)
        subjectLabel.text = teacher.resume[3]
        
    }
}
