//
//  ChatListCell.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/28.
//

import UIKit

class ChatListCell: UITableViewCell {
    
    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let lastMessageLabel = UILabel()
    private let timeLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        
        self.selectionStyle = .none
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 30
        profileImageView.clipsToBounds = true
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.tintColor = .white
        profileImageView.contentMode = .scaleAspectFill
        
        nameLabel.font = UIFont.boldSystemFont(ofSize: 16)
        nameLabel.textColor = .white
        lastMessageLabel.font = UIFont.systemFont(ofSize: 14)
        lastMessageLabel.textColor = .gray
        timeLabel.font = UIFont.systemFont(ofSize: 12)
        timeLabel.textColor = .lightGray
        
        contentView.addSubview(profileImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(lastMessageLabel)
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        lastMessageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            profileImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 60),
            profileImageView.heightAnchor.constraint(equalToConstant: 60),
            
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            
            timeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            lastMessageLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            lastMessageLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            lastMessageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    
    func configure(name: String, lastMessage: String, time: String, image: String) {
        print(name)
        nameLabel.text = name
        lastMessageLabel.text = lastMessage
        timeLabel.text = time
        
        if let imageURL = URL(string: image) {
            profileImageView.kf.setImage(with: imageURL, placeholder: UIImage(systemName: "person.crop.circle.fill"))
        } else {
            profileImageView.image = UIImage(systemName: "person.crop.circle.fill")
        }
    }
}
