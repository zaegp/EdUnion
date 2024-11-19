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
    private let userID = UserSession.shared.unwrappedUserID
    
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
    
    private let readReceiptLabel: UILabel = {
            let label = UILabel()
            label.font = UIFont.preferredFont(forTextStyle: .caption2)
            label.textColor = .gray
            label.text = "已讀"
            label.translatesAutoresizingMaskIntoConstraints = false
            label.isHidden = true
            return label
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
    
    private var readReceiptTrailingConstraint: NSLayoutConstraint!
       
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
        contentView.addSubview(messageImageView)
        contentView.addSubview(activityIndicator)
        contentView.addSubview(timestampLabel)
        contentView.addSubview(readReceiptLabel)
        
        toggleImageButton.addTarget(self, action: #selector(toggleImageButtonTapped), for: .touchUpInside)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        messageImageView.isUserInteractionEnabled = true
        messageImageView.addGestureRecognizer(tapGesture)
    }
    
    private func setupConstraints() {
        setupBubbleConstraints()
        setupMessageLabelConstraints()
        setupToggleImageButtonConstraints()
        setupActivityIndicatorConstraints()
        setupImageViewConstraints()
        setupTimestampLabelConstraints()
        setupReadReceiptLabelConstraints()
    }

    private func setupBubbleConstraints() {
        bubbleTopConstraint = bubbleBackgroundView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24)
        bubbleBottomConstraint = bubbleBackgroundView.bottomAnchor.constraint(
            equalTo: contentView.bottomAnchor,
            constant: -4
        )
        
        bubbleTrailingConstraint = bubbleBackgroundView.trailingAnchor.constraint(
            equalTo: contentView.trailingAnchor,
            constant: -16
        )
        bubbleLeadingConstraintGreater = bubbleBackgroundView.leadingAnchor.constraint(
            greaterThanOrEqualTo: contentView.leadingAnchor,
            constant: 100
        )
        
        bubbleLeadingConstraint = bubbleBackgroundView.leadingAnchor.constraint(
            equalTo: contentView.leadingAnchor,
            constant: 16
        )
        bubbleTrailingConstraintLess = bubbleBackgroundView.trailingAnchor.constraint(
            lessThanOrEqualTo: contentView.trailingAnchor,
            constant: -100
        )
        
        bubbleWidthConstraint = bubbleBackgroundView.widthAnchor.constraint(equalToConstant: 200)
        bubbleHeightConstraint = bubbleBackgroundView.heightAnchor.constraint(equalToConstant: 40)
        
        NSLayoutConstraint.activate([
            bubbleTopConstraint,
            bubbleBottomConstraint
        ])
    }

    private func setupMessageLabelConstraints() {
        messageLabel.setContentHuggingPriority(.required, for: .horizontal)
        messageLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: bubbleBackgroundView.topAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleBackgroundView.leadingAnchor, constant: 8),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleBackgroundView.trailingAnchor, constant: -8),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleBackgroundView.bottomAnchor, constant: -8)
        ])
    }

    private func setupToggleImageButtonConstraints() {
        NSLayoutConstraint.activate([
            toggleImageButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 8),
            toggleImageButton.leadingAnchor.constraint(equalTo: bubbleBackgroundView.leadingAnchor, constant: 8),
            toggleImageButton.trailingAnchor.constraint(equalTo: bubbleBackgroundView.trailingAnchor, constant: -8),
            toggleImageButton.heightAnchor.constraint(equalToConstant: 30),
            toggleImageButton.bottomAnchor.constraint(equalTo: bubbleBackgroundView.bottomAnchor, constant: -8)
        ])
    }

    private func setupActivityIndicatorConstraints() {
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: messageImageView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: messageImageView.centerYAnchor)
        ])
    }

    private func setupImageViewConstraints() {
        imageTopConstraint = messageImageView.topAnchor.constraint(
            equalTo: contentView.topAnchor,
            constant: 24
        )
        imageBottomConstraint = messageImageView.bottomAnchor.constraint(
            equalTo: contentView.bottomAnchor,
            constant: -4
        )
        
        imageLeadingConstraint = messageImageView.leadingAnchor.constraint(
            equalTo: contentView.leadingAnchor,
            constant: 16
        )
        imageTrailingConstraint = messageImageView.trailingAnchor.constraint(
            equalTo: contentView.trailingAnchor,
            constant: -16
        )
        imageWidthConstraint = messageImageView.widthAnchor.constraint(equalToConstant: 200)
        imageHeightConstraint = messageImageView.heightAnchor.constraint(equalToConstant: 200)
    }
    
    private func setupImageConstraints(isSentByCurrentUser: Bool) {
        imageTopConstraint.isActive = true
        imageBottomConstraint.isActive = true
        imageWidthConstraint.isActive = true
        imageHeightConstraint.isActive = true
        
        if isSentByCurrentUser {
            imageLeadingConstraint.isActive = false
            imageTrailingConstraint.isActive = true
        } else {
            imageTrailingConstraint.isActive = false
            imageLeadingConstraint.isActive = true
        }
    }

    private func setupTimestampLabelConstraints() {
        NSLayoutConstraint.activate([
            timestampLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            timestampLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])
    }
    
    private func setupReadReceiptLabelConstraints() {
        readReceiptTrailingConstraint = readReceiptLabel.trailingAnchor.constraint(equalTo: bubbleBackgroundView.leadingAnchor, constant: -4)

        NSLayoutConstraint.activate([
            readReceiptLabel.heightAnchor.constraint(equalToConstant: 14),
            readReceiptLabel.bottomAnchor.constraint(equalTo: bubbleBackgroundView.bottomAnchor)
        ])
    }
    
    func configure(with message: Message, previousMessage: Message?, image: UIImage?) {
        self.message = message
        self.isSentByCurrentUser = (message.senderID == userID)
        resetContent()

        if shouldShowTimestamp(for: message, previousMessage: previousMessage) {
            timestampLabel.text = TimeService.formattedChatDate(from: message.timestamp.dateValue())
            timestampLabel.isHidden = false
        }

        switch message.type {
        case 0:
            configureTextMessage(message: message)

        case 1:
            configureImageMessage(message: message, image: image)

        case 2:
            configureSystemMessage(message: message)

        default:
            hideAllViews()
        }

        if !isSentByCurrentUser {
            readReceiptLabel.isHidden = true
        }
        
        updateBubbleAppearance()
    }

    private func configureTextMessage(message: Message) {
        bubbleBackgroundView.isHidden = false
        messageImageView.isHidden = true
        toggleImageButton.isHidden = true

        setupBubbleConstraints(isSentByCurrentUser: isSentByCurrentUser)
        messageLabel.text = " " + message.content + " "
        messageLabel.isHidden = false

        if isSentByCurrentUser && message.isSeen {
            readReceiptTrailingConstraint.isActive = true
            readReceiptLabel.isHidden = false
        } else {
            readReceiptLabel.isHidden = true
        }
    }

    private func configureImageMessage(message: Message, image: UIImage?) {
        bubbleBackgroundView.isHidden = true
        messageImageView.isHidden = false
        toggleImageButton.isHidden = false

        setupImageConstraints(isSentByCurrentUser: isSentByCurrentUser)

        if let localImage = image {
            messageImageView.image = localImage
            activityIndicator.stopAnimating()
        } else {
            messageImageView.image = nil
            loadImage(from: message.content)
            activityIndicator.startAnimating()
        }

        if isSentByCurrentUser && message.isSeen {
            NSLayoutConstraint.activate([
                readReceiptLabel.trailingAnchor.constraint(equalTo: messageImageView.leadingAnchor, constant: -4),
                readReceiptLabel.bottomAnchor.constraint(equalTo: messageImageView.bottomAnchor)
            ])
            readReceiptLabel.isHidden = false
        } else {
            readReceiptLabel.isHidden = true
        }
    }

    private func configureSystemMessage(message: Message) {
        bubbleBackgroundView.isHidden = false
        messageImageView.isHidden = true
        toggleImageButton.isHidden = true

        setupBubbleConstraints(isSentByCurrentUser: isSentByCurrentUser)
        messageLabel.text = " 已離開課堂 "
        messageLabel.isHidden = false

        readReceiptLabel.isHidden = true
    }

    private func hideAllViews() {
        bubbleBackgroundView.isHidden = true
        messageImageView.isHidden = true
        toggleImageButton.isHidden = true
        messageLabel.isHidden = true
        readReceiptLabel.isHidden = true
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
    
    private func loadImage(from urlString: String) {
        if let url = URL(string: urlString) {
            messageImageView.kf.setImage(with: url) { result in
                switch result {
                case .success:
                    DispatchQueue.main.async {
                        self.activityIndicator.stopAnimating()
                    }
                case .failure(let error):
                    print("圖片加載失敗: \(error)")
                }
            }
        } else {
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
