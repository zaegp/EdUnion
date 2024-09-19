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
    private let highlightsLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        highlightsLabel.numberOfLines = 0

        contentView.addSubview(image)
        contentView.addSubview(nameLabel)
        contentView.addSubview(totalCoursesLabel)
        contentView.addSubview(highlightsLabel)

        image.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        totalCoursesLabel.translatesAutoresizingMaskIntoConstraints = false
        highlightsLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            image.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            image.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            nameLabel.topAnchor.constraint(equalTo: image.bottomAnchor, constant: 8),
            nameLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            totalCoursesLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            totalCoursesLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            highlightsLabel.topAnchor.constraint(equalTo: totalCoursesLabel.bottomAnchor, constant: 8),
            highlightsLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with teacher: Teacher) {
        let url = URL(string: teacher.photoURL)
        image.kf.setImage(with: url)
        
        nameLabel.text = teacher.name
        
        totalCoursesLabel.text = String(teacher.totalCourses)
        
        highlightsLabel.text = teacher.resume[3]
    }
}
