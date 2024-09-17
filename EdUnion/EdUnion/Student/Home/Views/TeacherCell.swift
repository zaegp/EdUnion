//
//  TeacherCell.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/14.
//

import UIKit
import Kingfisher

class TeacherCell: UICollectionViewCell {

    private let nameLabel = UILabel()
    private let image = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(nameLabel)
        contentView.addSubview(image)

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        image.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            
            image.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 5),
            image.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with teacher: Teacher) {
        nameLabel.text = teacher.name
        let url = URL(string: teacher.photoURL)
        image.kf.setImage(with: url)
    }
}

