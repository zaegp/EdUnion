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
    let activityIndicator = UIActivityIndicatorView(style: .medium)

    override init(frame: CGRect) {
        super.init(frame: frame)

        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .mainOrange
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)

        nameLabel.font = UIFont.systemFont(ofSize: 12)
        nameLabel.textAlignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)
        
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
                contentView.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            imageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 50),
            imageView.heightAnchor.constraint(equalToConstant: 50),

            nameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 5),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5),
            
            activityIndicator.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
                        activityIndicator.centerYAnchor.constraint(equalTo: imageView.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with fileURL: URL, isDownloading: Bool) {
        nameLabel.text = fileURL.lastPathComponent
        imageView.image = UIImage(systemName: isDownloading ? "arrow.down.doc" : "doc")
        if isDownloading {
                    activityIndicator.startAnimating()
                } else {
                    activityIndicator.stopAnimating()
                }
    }

    func setSelected(_ selected: Bool) {
        imageView.image = selected ? UIImage(systemName: "doc.fill") : UIImage(systemName: "doc")
    }
}
