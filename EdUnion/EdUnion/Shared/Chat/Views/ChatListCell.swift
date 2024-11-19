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
    
    private let skeletonProfileView = UIView()
    private let skeletonNameView = UIView()
    private let skeletonMessageView = UIView()
    
    var isSkeleton: Bool = false {
        didSet {
            configureSkeletonState()
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 30
        profileImageView.clipsToBounds = true
        profileImageView.tintColor = .myMessageCell
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        
        nameLabel.font = UIFont.boldSystemFont(ofSize: 16)
        nameLabel.textColor = .label
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        lastMessageLabel.font = UIFont.systemFont(ofSize: 14)
        lastMessageLabel.textColor = .secondaryLabel
        lastMessageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        timeLabel.font = UIFont.systemFont(ofSize: 12)
        timeLabel.textColor = .secondaryLabel
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        badgeView.backgroundColor = .mainOrange
        badgeView.layer.cornerRadius = 10
        badgeView.isHidden = true
        badgeView.translatesAutoresizingMaskIntoConstraints = false
        
        badgeLabel.font = UIFont.systemFont(ofSize: 12)
        badgeLabel.textColor = .white
        badgeLabel.textAlignment = .center
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        badgeView.addSubview(badgeLabel)
        
        contentView.addSubview(profileImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(lastMessageLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(badgeView)
        
        skeletonProfileView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
        skeletonProfileView.layer.cornerRadius = 30
        skeletonProfileView.translatesAutoresizingMaskIntoConstraints = false
        skeletonProfileView.isHidden = true
        
        skeletonNameView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
        skeletonNameView.layer.cornerRadius = 5
        skeletonNameView.translatesAutoresizingMaskIntoConstraints = false
        skeletonNameView.isHidden = true
        
        skeletonMessageView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
        skeletonMessageView.layer.cornerRadius = 5
        skeletonMessageView.translatesAutoresizingMaskIntoConstraints = false
        skeletonMessageView.isHidden = true
        
        contentView.addSubview(skeletonProfileView)
        contentView.addSubview(skeletonNameView)
        contentView.addSubview(skeletonMessageView)
        
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
            badgeLabel.centerYAnchor.constraint(equalTo: badgeView.centerYAnchor),
            
            skeletonProfileView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            skeletonProfileView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            skeletonProfileView.widthAnchor.constraint(equalToConstant: 60),
            skeletonProfileView.heightAnchor.constraint(equalToConstant: 60),
            
            skeletonNameView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            skeletonNameView.leadingAnchor.constraint(equalTo: skeletonProfileView.trailingAnchor, constant: 12),
            skeletonNameView.widthAnchor.constraint(equalToConstant: 120),
            skeletonNameView.heightAnchor.constraint(equalToConstant: 16),
            
            skeletonMessageView.topAnchor.constraint(equalTo: skeletonNameView.bottomAnchor, constant: 8),
            skeletonMessageView.leadingAnchor.constraint(equalTo: skeletonProfileView.trailingAnchor, constant: 12),
            skeletonMessageView.widthAnchor.constraint(equalToConstant: 180),
            skeletonMessageView.heightAnchor.constraint(equalToConstant: 14)
        ])
    }
    
    private func configureSkeletonState() {
        let isHidden = !isSkeleton
        
        profileImageView.isHidden = !isHidden
        nameLabel.isHidden = !isHidden
        lastMessageLabel.isHidden = !isHidden
        timeLabel.isHidden = !isHidden
        badgeView.isHidden = !isHidden
        
        skeletonProfileView.isHidden = isHidden
        skeletonNameView.isHidden = isHidden
        skeletonMessageView.isHidden = isHidden
    }
    
    func configure(name: String, lastMessage: String, time: String, image: String, unreadCount: Int) {
        isSkeleton = false
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
