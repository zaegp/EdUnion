//
//  ChatTableViewCell.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/11.
//

import UIKit
import AVFoundation
import Kingfisher

protocol ChatTableViewCellDelegate: AnyObject {
    func chatTableViewCell(_ cell: ChatTableViewCell, didTapImage image: UIImage)
}

class ChatTableViewCell: UITableViewCell {
    
    private var isImageLoaded = false
    let userID = UserSession.shared.currentUserID
    
    private let bubbleBackgroundView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let messageImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 16
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isHidden = true
        return imageView
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private let timestampLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .caption2)
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .gray
        return label
    }()
    
    private let toggleImageButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "arrow.2.circlepath"), for: .normal)
        button.setImage(UIImage(systemName: "arrow.2.circlepath.circle"), for: .selected)
        button.semanticContentAttribute = .forceLeftToRight
        return button
    }()
    
    weak var delegate: ChatTableViewCellDelegate?
    
    private var message: Message?
    
    private var imageLeadingConstraint: NSLayoutConstraint!
    private var imageTrailingConstraint: NSLayoutConstraint!
    private var imageWidthConstraint: NSLayoutConstraint!
    private var imageHeightConstraint: NSLayoutConstraint!
    
    private var bubbleLeadingConstraint: NSLayoutConstraint!
    private var bubbleTrailingConstraint: NSLayoutConstraint!
    private var bubbleWidthConstraint: NSLayoutConstraint!
    private var bubbleHeightConstraint: NSLayoutConstraint!
    
    private var bubbleTopConstraint: NSLayoutConstraint!
    private var bubbleBottomConstraint: NSLayoutConstraint!
    private var bubbleLeadingConstraintGreater: NSLayoutConstraint!
    private var bubbleTrailingConstraintLess: NSLayoutConstraint!
    
    private var imageTopConstraint: NSLayoutConstraint!
    private var imageBottomConstraint: NSLayoutConstraint!
    
    var isSentByCurrentUser: Bool = false {
        didSet {
            updateBubbleAppearance()
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupUI()
        setupConstraints()
        selectionStyle = .none
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(bubbleBackgroundView)
        bubbleBackgroundView.addSubview(messageLabel)
        bubbleBackgroundView.addSubview(toggleImageButton)
        bubbleBackgroundView.addSubview(activityIndicator)
        contentView.addSubview(messageImageView)
//        messageImageView.addSubview(activityIndicator)
        contentView.addSubview(timestampLabel)
        
        toggleImageButton.addTarget(self, action: #selector(toggleImageButtonTapped), for: .touchUpInside)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        messageImageView.isUserInteractionEnabled = true
        messageImageView.addGestureRecognizer(tapGesture)
    }
    
    private func setupConstraints() {
        bubbleTopConstraint = bubbleBackgroundView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24)
        bubbleBottomConstraint = bubbleBackgroundView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4)
        
        bubbleTrailingConstraint = bubbleBackgroundView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        bubbleLeadingConstraintGreater = bubbleBackgroundView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 100)
        
        bubbleLeadingConstraint = bubbleBackgroundView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        bubbleTrailingConstraintLess = bubbleBackgroundView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -100)
        
        bubbleWidthConstraint = bubbleBackgroundView.widthAnchor.constraint(equalToConstant: 200)
        bubbleHeightConstraint = bubbleBackgroundView.heightAnchor.constraint(equalToConstant: 40)
        
        NSLayoutConstraint.activate([
            bubbleTopConstraint,
            bubbleBottomConstraint
        ])
        
        messageLabel.setContentHuggingPriority(.required, for: .horizontal)
        messageLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: bubbleBackgroundView.topAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleBackgroundView.leadingAnchor, constant: 8),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleBackgroundView.trailingAnchor, constant: -8),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleBackgroundView.bottomAnchor, constant: -8)
        ])
        
        NSLayoutConstraint.activate([
            toggleImageButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 8),
            toggleImageButton.leadingAnchor.constraint(equalTo: bubbleBackgroundView.leadingAnchor, constant: 8),
            toggleImageButton.trailingAnchor.constraint(equalTo: bubbleBackgroundView.trailingAnchor, constant: -8),
            toggleImageButton.heightAnchor.constraint(equalToConstant: 30),
            toggleImageButton.bottomAnchor.constraint(equalTo: bubbleBackgroundView.bottomAnchor, constant: -8)
        ])
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: messageImageView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: messageImageView.centerYAnchor)
        ])
        
        imageTopConstraint = messageImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24)
        imageBottomConstraint = messageImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4)
        
        imageLeadingConstraint = messageImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        imageTrailingConstraint = messageImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        imageWidthConstraint = messageImageView.widthAnchor.constraint(equalToConstant: 200)
        imageHeightConstraint = messageImageView.heightAnchor.constraint(equalToConstant: 200)
        
        NSLayoutConstraint.activate([
            imageTopConstraint,
            imageBottomConstraint,
            imageLeadingConstraint,
            imageTrailingConstraint,
            imageWidthConstraint,
            imageHeightConstraint
        ])
        
        NSLayoutConstraint.deactivate([
            imageTopConstraint,
            imageBottomConstraint,
            imageLeadingConstraint,
            imageTrailingConstraint,
            imageWidthConstraint,
            imageHeightConstraint
        ])
        
        NSLayoutConstraint.activate([
            timestampLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            timestampLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])
    }
    
    func configure(with message: Message, previousMessage: Message?, image: UIImage?) {
        self.message = message
        
        self.isSentByCurrentUser = (message.senderID == userID)
        resetContent()
        
        if shouldShowTimestamp(for: message, previousMessage: previousMessage) {
            timestampLabel.text = TimeService.covertToChatRoomFormat(message.timestamp.dateValue())
            timestampLabel.isHidden = false
        }
        
        switch message.type {
        case 0:
            bubbleBackgroundView.isHidden = false
            messageImageView.isHidden = true
            toggleImageButton.isHidden = true
            setupBubbleConstraints(isSentByCurrentUser: isSentByCurrentUser)
            messageLabel.text = " " + message.content + " "
            messageLabel.isHidden = false
        case 1:
            bubbleBackgroundView.isHidden = true
            messageImageView.isHidden = false
            toggleImageButton.isHidden = false
            setupImageConstraints(isSentByCurrentUser: isSentByCurrentUser)
            
            if let localImage = image {
                messageImageView.image = localImage
                activityIndicator.stopAnimating()
            } else {
                messageImageView.image = nil
                activityIndicator.startAnimating()
                loadImage(from: message.content)
            }
            
        case 2:  
                bubbleBackgroundView.isHidden = false
                messageImageView.isHidden = true
                toggleImageButton.isHidden = true
                setupBubbleConstraints(isSentByCurrentUser: isSentByCurrentUser)
                messageLabel.text = " 已離開課堂 "
                messageLabel.isHidden = false
        default:
            bubbleBackgroundView.isHidden = true
            messageImageView.isHidden = true
            toggleImageButton.isHidden = true
            messageLabel.isHidden = true
        }
        
        updateBubbleAppearance()
    }
    
    private func shouldShowTimestamp(for message: Message, previousMessage: Message?) -> Bool {
        guard let previousMessage = previousMessage else {
            return true
        }
        
        let timeInterval: TimeInterval = 180
        let timeDifference = message.timestamp.dateValue().timeIntervalSince(previousMessage.timestamp.dateValue())
        
        return timeDifference > timeInterval
    }
    
    private func resetContent() {
        messageLabel.isHidden = true
        messageImageView.isHidden = true
        toggleImageButton.isHidden = true
        bubbleBackgroundView.isHidden = false
        timestampLabel.text = nil
        messageLabel.text = nil
        
        messageImageView.image = nil
        
        activityIndicator.stopAnimating()
        
        NSLayoutConstraint.deactivate([
            imageTopConstraint,
            imageBottomConstraint,
            imageLeadingConstraint,
            imageTrailingConstraint,
            imageWidthConstraint,
            imageHeightConstraint,
            bubbleWidthConstraint,
            bubbleHeightConstraint
        ])
    }
    
    private func updateBubbleAppearance() {
        guard !bubbleBackgroundView.isHidden else { return }
        bubbleBackgroundView.backgroundColor = isSentByCurrentUser ? .myMessageCell : .myGray
        messageLabel.textColor = isSentByCurrentUser ? .systemBackground : .black
    }
    
    private func setupBubbleConstraints(isSentByCurrentUser: Bool) {
        if isSentByCurrentUser {
            bubbleTrailingConstraint.isActive = true
            bubbleLeadingConstraintGreater.isActive = true
            
            bubbleLeadingConstraint.isActive = false
            bubbleTrailingConstraintLess.isActive = false
        } else {
            bubbleLeadingConstraint.isActive = true
            bubbleTrailingConstraintLess.isActive = true
            
            bubbleTrailingConstraint.isActive = false
            bubbleLeadingConstraintGreater.isActive = false
        }
    }
    
    private func setupImageConstraints(isSentByCurrentUser: Bool) {
        if isSentByCurrentUser {
            imageLeadingConstraint.isActive = false
            imageTrailingConstraint.isActive = true
        } else {
            imageTrailingConstraint.isActive = false
            imageLeadingConstraint.isActive = true
        }
        
        NSLayoutConstraint.activate([
            imageTopConstraint,
            imageBottomConstraint,
            imageWidthConstraint,
            imageHeightConstraint
        ])
    }
    
    private func loadImage(from urlString: String) {
        if let url = URL(string: urlString) {
            messageImageView.kf.setImage(with: url) { result in
                self.activityIndicator.stopAnimating()
                switch result {
                case .success(_):
                    break
                case .failure(let error):
                    print("圖片加載失敗: \(error)")
                }
            }
        } else {
            activityIndicator.stopAnimating()
            print("無效的圖片URL")
        }
    }
    
    @objc private func toggleImageButtonTapped() {
        toggleImageButton.isSelected.toggle()
    }
    
    @objc private func imageTapped() {
        guard let image = messageImageView.image else { return }
        delegate?.chatTableViewCell(self, didTapImage: image)
    }
}
