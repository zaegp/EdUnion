//
//  FilesCell.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/30.
//

import UIKit

class FileCell: UICollectionViewCell {
    let imageView = UIImageView()
    let nameLabel = UILabel()
    let overlayView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)

        nameLabel.font = UIFont.systemFont(ofSize: 12)
        nameLabel.textAlignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)

        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlayView.isHidden = true
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(overlayView)

        // AutoLayout Constraints
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            imageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 50),
            imageView.heightAnchor.constraint(equalToConstant: 50),

            nameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 5),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5),

            // 覆蓋視圖佈局
            overlayView.topAnchor.constraint(equalTo: contentView.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            overlayView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with fileURL: URL) {
        nameLabel.text = fileURL.lastPathComponent
        imageView.image = UIImage(systemName: "doc")
    }

    func setSelected(_ selected: Bool) {
        overlayView.isHidden = !selected
    }
}
