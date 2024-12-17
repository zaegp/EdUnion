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
    
    private let skeletonImageView = UIView()
    private let skeletonNameView = UIView()
    private let skeletonSubjectView = UIView()
    private let skeletonEducationView = UIView()
    private let skeletonExperienceView = UIView()
    
    var isSkeleton: Bool = false {
        didSet {
            configureSkeletonState()
        }
    }
    
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
        
        setupSkeletonViews()
    }
    
    private func setupSkeletonViews() {
        let skeletons = [skeletonImageView, skeletonNameView, skeletonSubjectView, skeletonEducationView, skeletonExperienceView]
        skeletons.forEach {
            $0.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
            $0.layer.cornerRadius = 8
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.isHidden = true
            contentView.addSubview($0)
        }
        
        skeletonImageView.layer.cornerRadius = 40
        skeletonImageView.clipsToBounds = true
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
        
        NSLayoutConstraint.activate([
            skeletonImageView.widthAnchor.constraint(equalToConstant: 80),
            skeletonImageView.heightAnchor.constraint(equalToConstant: 80),
            skeletonImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            skeletonImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            
            skeletonNameView.topAnchor.constraint(equalTo: skeletonImageView.bottomAnchor, constant: 16),
            skeletonNameView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            skeletonNameView.widthAnchor.constraint(equalToConstant: 120),
            skeletonNameView.heightAnchor.constraint(equalToConstant: 16),
            
            skeletonSubjectView.topAnchor.constraint(equalTo: skeletonNameView.bottomAnchor, constant: 8),
            skeletonSubjectView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            skeletonSubjectView.widthAnchor.constraint(equalToConstant: 100),
            skeletonSubjectView.heightAnchor.constraint(equalToConstant: 14),
            
            skeletonEducationView.topAnchor.constraint(equalTo: skeletonSubjectView.bottomAnchor, constant: 8),
            skeletonEducationView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            skeletonEducationView.widthAnchor.constraint(equalToConstant: 140),
            skeletonEducationView.heightAnchor.constraint(equalToConstant: 14),
            
            skeletonExperienceView.topAnchor.constraint(equalTo: skeletonEducationView.bottomAnchor, constant: 8),
            skeletonExperienceView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            skeletonExperienceView.widthAnchor.constraint(equalToConstant: 160),
            skeletonExperienceView.heightAnchor.constraint(equalToConstant: 14)
        ])
    }
    
    private func configureSkeletonState() {
        let isHidden = !isSkeleton
        
        image.isHidden = isSkeleton
        nameLabel.isHidden = isSkeleton
        totalCoursesLabel.isHidden = isSkeleton
        subjectLabel.isHidden = isSkeleton
        educationLabel.isHidden = isSkeleton
        experienceLabel.isHidden = isSkeleton
        
        skeletonImageView.isHidden = isHidden
        skeletonNameView.isHidden = isHidden
        skeletonSubjectView.isHidden = isHidden
        skeletonEducationView.isHidden = isHidden
        skeletonExperienceView.isHidden = isHidden
    }
    
    func configure(with teacher: Teacher) {
        isSkeleton = false
        
        if let photoURL = teacher.photoURL, let url = URL(string: photoURL) {
            image.kf.setImage(with: url, placeholder: UIImage(systemName: "person.crop.circle.fill"))
        } else {
            image.image = UIImage(systemName: "person.crop.circle.fill")
        }
        image.tintColor = .myMessageCell
        
        nameLabel.text = teacher.fullName
        totalCoursesLabel.text = "已在平台上 \(teacher.totalCourses) 節課"
        subjectLabel.text = "教學科目: \(teacher.resume[3])"
        educationLabel.text = "學歷: \(teacher.resume[0])"
        experienceLabel.text = "家教經驗: \(teacher.resume[1])"
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        image.image = nil
        image.kf.cancelDownloadTask()
        
        nameLabel.text = nil
        totalCoursesLabel.text = nil
        subjectLabel.text = nil
        educationLabel.text = nil
        experienceLabel.text = nil
        
        isSkeleton = false
    }
}
