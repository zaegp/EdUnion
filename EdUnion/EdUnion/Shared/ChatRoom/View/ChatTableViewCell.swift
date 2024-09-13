//
//  ChatTableViewCell.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/11.
//

import UIKit

class ChatTableViewCell: UITableViewCell {
    
    private let messageLabel = UILabel()
    private let bubbleBackgroundView = UIView()
    private let timestampLabel = UILabel()
    
    var isSentByCurrentUser: Bool = false {
        didSet {
            bubbleBackgroundView.backgroundColor = isSentByCurrentUser ? .systemBlue : .lightGray
            messageLabel.textColor = isSentByCurrentUser ? .white : .black
            timestampLabel.textColor = isSentByCurrentUser ? .white.withAlphaComponent(0.8) : .black.withAlphaComponent(0.6)
            
            let leadingConstraint = bubbleBackgroundView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16)
            let trailingConstraint = bubbleBackgroundView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
            
            if isSentByCurrentUser {
                leadingConstraint.isActive = false
                trailingConstraint.isActive = true
            } else {
                leadingConstraint.isActive = true
                trailingConstraint.isActive = false
            }
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        bubbleBackgroundView.layer.cornerRadius = 12
        bubbleBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bubbleBackgroundView)
        
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(messageLabel)
        
        timestampLabel.font = UIFont.systemFont(ofSize: 10)
        timestampLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(timestampLabel)
        
        NSLayoutConstraint.activate([
            bubbleBackgroundView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            bubbleBackgroundView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            bubbleBackgroundView.widthAnchor.constraint(lessThanOrEqualToConstant: 250),
            
            messageLabel.topAnchor.constraint(equalTo: bubbleBackgroundView.topAnchor, constant: 8),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleBackgroundView.bottomAnchor, constant: -8),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleBackgroundView.leadingAnchor, constant: 8),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleBackgroundView.trailingAnchor, constant: -8),
            
            timestampLabel.topAnchor.constraint(equalTo: bubbleBackgroundView.bottomAnchor, constant: 4),
            timestampLabel.trailingAnchor.constraint(equalTo: bubbleBackgroundView.trailingAnchor, constant: -8)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with message: String, isSentByCurrentUser: Bool, timestamp: Date) {
        messageLabel.text = message
        self.isSentByCurrentUser = isSentByCurrentUser
        timestampLabel.text = formatDate(timestamp)
    }
    
    // 格式化日期顯示
    private func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        return dateFormatter.string(from: date)
    }
}
