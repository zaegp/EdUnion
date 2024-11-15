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
    private let badgeView = UIView()
        private let badgeLabel = UILabel()
    
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
        profileImageView.tintColor = .myMessageCell
        profileImageView.contentMode = .scaleAspectFill
        
        nameLabel.font = UIFont.boldSystemFont(ofSize: 16)
        nameLabel.textColor = .label
        
        lastMessageLabel.font = UIFont.systemFont(ofSize: 14)
        lastMessageLabel.textColor = .secondaryLabel
        
        timeLabel.font = UIFont.systemFont(ofSize: 12)
        timeLabel.textColor = .secondaryLabel
        
        badgeView.backgroundColor = .mainOrange
        badgeView.layer.cornerRadius = 10
        badgeView.translatesAutoresizingMaskIntoConstraints = false
        badgeView.isHidden = true
        
        badgeLabel.font = UIFont.systemFont(ofSize: 12)
        badgeLabel.textColor = .white
        badgeLabel.textAlignment = .center
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        badgeView.addSubview(badgeLabel)
        
        contentView.addSubview(profileImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(lastMessageLabel)
        contentView.addSubview(badgeView)
        
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
            lastMessageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            badgeView.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 8),
            badgeView.trailingAnchor.constraint(equalTo: timeLabel.trailingAnchor),
            badgeView.widthAnchor.constraint(equalToConstant: 20),
            badgeView.heightAnchor.constraint(equalToConstant: 20),
            
            badgeLabel.centerXAnchor.constraint(equalTo: badgeView.centerXAnchor),
                        badgeLabel.centerYAnchor.constraint(equalTo: badgeView.centerYAnchor)
        ])
    }
    
    func configure(name: String, lastMessage: String, time: String, image: String, unreadCount: Int) {
        print(name)
        nameLabel.text = name
        lastMessageLabel.text = lastMessage
        timeLabel.text = time
        
        if let imageURL = URL(string: image) {
            profileImageView.kf.setImage(with: imageURL, placeholder: UIImage(systemName: "person.crop.circle.fill"))
        } else {
            profileImageView.image = UIImage(systemName: "person.crop.circle.fill")
        }
        
        updateUnreadCount(unreadCount)
    }
    
    func updateUnreadCount(_ unreadCount: Int) {
        if unreadCount > 0 {
            badgeLabel.text = unreadCount > 99 ? "99+" : "\(unreadCount)"
            badgeView.isHidden = false
        } else {
            badgeView.isHidden = true
        }
    }
}
