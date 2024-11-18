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
        image.layer.cornerRadius = 40
        image.clipsToBounds = true
        image.contentMode = .scaleAspectFill
        image.translatesAutoresizingMaskIntoConstraints = false
        
        [nameLabel, totalCoursesLabel, subjectLabel, educationLabel, experienceLabel].forEach {
            $0.textAlignment = .center
            $0.numberOfLines = 1
            $0.lineBreakMode = .byTruncatingTail 
            $0.font = UIFont.systemFont(ofSize: 14)
        }
        nameLabel.font = UIFont.boldSystemFont(ofSize: 18)
        nameLabel.textColor = .myMessageCell
        totalCoursesLabel.textColor = .myMessageCell
        subjectLabel.textColor = .myMessageCell
        educationLabel.textColor = .myMessageCell
        experienceLabel.textColor = .myMessageCell
        
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.addArrangedSubview(image)
        stackView.addArrangedSubview(nameLabel)
        stackView.addArrangedSubview(subjectLabel)
        stackView.addArrangedSubview(educationLabel)
        stackView.addArrangedSubview(experienceLabel)
        stackView.addArrangedSubview(totalCoursesLabel)
        
        contentView.addSubview(stackView)
        
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -16)
        ])
        
        NSLayoutConstraint.activate([
            image.widthAnchor.constraint(equalToConstant: 80),
            image.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    func configure(with teacher: Teacher) {
        
        image.image = nil

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
