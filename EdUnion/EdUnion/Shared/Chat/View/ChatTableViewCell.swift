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
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isHidden = true
        return imageView
    }()
    
    private let audioButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("播放音訊", for: .normal)
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        button.setImage(UIImage(systemName: "play.fill"), for: .normal)
        button.setImage(UIImage(systemName: "stop.fill"), for: .selected)
        button.semanticContentAttribute = .forceRightToLeft
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: -8)
        return button
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
    
    private var audioPlayer: AVAudioPlayer?
    private var message: Message?
    
    private var bubbleLeadingConstraint: NSLayoutConstraint!
    private var bubbleTrailingConstraint: NSLayoutConstraint!
    
    private var imageLeadingConstraint: NSLayoutConstraint!
    private var imageTrailingConstraint: NSLayoutConstraint!
    private var imageWidthConstraint: NSLayoutConstraint!
    private var imageHeightConstraint: NSLayoutConstraint!
    
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
        bubbleBackgroundView.addSubview(audioButton)
        bubbleBackgroundView.addSubview(toggleImageButton)
        bubbleBackgroundView.addSubview(activityIndicator)
        contentView.addSubview(messageImageView)
        contentView.addSubview(timestampLabel)
        
        audioButton.addTarget(self, action: #selector(playAudio), for: .touchUpInside)
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
            audioButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 8),
            audioButton.leadingAnchor.constraint(equalTo: bubbleBackgroundView.leadingAnchor, constant: 8),
            audioButton.trailingAnchor.constraint(equalTo: bubbleBackgroundView.trailingAnchor, constant: -8),
            audioButton.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        NSLayoutConstraint.activate([
            toggleImageButton.topAnchor.constraint(equalTo: audioButton.bottomAnchor, constant: 8),
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
        // 要換
//        self.isSentByCurrentUser = (message.senderID == teacherID)
        self.isSentByCurrentUser = (message.senderID == studentID)
        resetContent()
        
        if shouldShowTimestamp(for: message, previousMessage: previousMessage) {
            timestampLabel.text = formatDate(message.timestamp.dateValue())
            timestampLabel.isHidden = false
        }
//         else {
//            timestampLabel.isHidden = true
//        }

        switch message.type {
        case 0:
            bubbleBackgroundView.isHidden = false
            messageImageView.isHidden = true
            toggleImageButton.isHidden = true
            setupBubbleConstraints(isSentByCurrentUser: isSentByCurrentUser)
            messageLabel.text = message.content
            messageLabel.isHidden = false

        case 1:
            bubbleBackgroundView.isHidden = true
            messageImageView.isHidden = false
            toggleImageButton.isHidden = false
            setupImageConstraints(isSentByCurrentUser: isSentByCurrentUser)
            
            if let localImage = image {
                messageImageView.image = localImage
                activityIndicator.startAnimating()
            } else {
                loadImage(from: message.content)
            }
//        case 1:
//                bubbleBackgroundView.isHidden = true
//                messageImageView.isHidden = false
//                toggleImageButton.isHidden = false
//                setupImageConstraints(isSentByCurrentUser: isSentByCurrentUser)
//
//                // 直接從 message.content 重新載入圖片
//                loadImage(from: message.content)

        case 2:
            bubbleBackgroundView.isHidden = false
                messageLabel.isHidden = true
                messageImageView.isHidden = true
                audioButton.isHidden = false
                toggleImageButton.isHidden = true
                setupBubbleConstraints(isSentByCurrentUser: isSentByCurrentUser)

        default:
            bubbleBackgroundView.isHidden = true
            messageImageView.isHidden = true
            toggleImageButton.isHidden = true
            messageLabel.isHidden = true
            audioButton.isHidden = true
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
        audioButton.isHidden = true
        toggleImageButton.isHidden = true
        bubbleBackgroundView.isHidden = false
        timestampLabel.text = nil
        messageLabel.text = nil
        messageImageView.image = nil
        audioPlayer = nil
        activityIndicator.stopAnimating()
        
        NSLayoutConstraint.deactivate([
            imageTopConstraint,
            imageBottomConstraint,
            imageLeadingConstraint,
            imageTrailingConstraint,
            imageWidthConstraint,
            imageHeightConstraint
        ])
        
//        NSLayoutConstraint.deactivate([
//            bubbleLeadingConstraint,
//            bubbleTrailingConstraint
//        ])
    }
    
    private func updateBubbleAppearance() {
        guard !bubbleBackgroundView.isHidden else { return }
        bubbleBackgroundView.backgroundColor = isSentByCurrentUser ? .systemOrange : .systemGray5
        messageLabel.textColor = isSentByCurrentUser ? .white : .black
//        timestampLabel.textColor = isSentByCurrentUser ? .white.withAlphaComponent(0.8) : .black.withAlphaComponent(0.6)
    }
    
    

    // 根據發送者啟用約束
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
    
//    private func loadImage(from urlString: String) {
//        guard let url = URL(string: urlString) else { return }
//        
//        let processor = DownsamplingImageProcessor(size: CGSize(width: 200, height: 200))
//        messageImageView.kf.indicatorType = .activity
//        messageImageView.kf.setImage(
//            with: url,
////            placeholder: UIImage(systemName: "photo"),
//            options: [
//                .processor(processor),
//                .scaleFactor(UIScreen.main.scale),
//                .transition(.fade(0.3)),
//                .cacheOriginalImage
//            ]) { [weak self] result in
//                switch result {
//                case .success(_):
//                    self?.activityIndicator.stopAnimating()
//                case .failure(let error):
//                    print("圖片加載失敗: \(error.localizedDescription)")
//                    self?.activityIndicator.stopAnimating()
//                }
//            }
//    }
    
    private func loadImage(from urlString: String) {
        if let url = URL(string: urlString) {
            messageImageView.kf.setImage(with: url) { result in
                switch result {
                case .success(_):
                    self.activityIndicator.stopAnimating()
                case .failure(let error):
                    print("圖片加載失敗: \(error)")
                    self.activityIndicator.stopAnimating()
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    @objc private func playAudio() {
        guard let audioURLString = message?.content,
              let url = URL(string: audioURLString) else {
            print("無效的音訊 URL")
            return
        }
        
        if let player = audioPlayer, player.isPlaying {
            player.stop()
            audioPlayer = nil
            audioButton.setTitle("播放音訊", for: .normal)
            audioButton.isSelected = false
            return
        }
        
        audioButton.setTitle("載入中...", for: .normal)
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            do {
                let audioData = try Data(contentsOf: url)
                self.audioPlayer = try AVAudioPlayer(data: audioData)
                self.audioPlayer?.delegate = self
                self.audioPlayer?.prepareToPlay()
                DispatchQueue.main.async {
                    self.audioPlayer?.play()
                    self.audioButton.setTitle("停止播放", for: .normal)
                    self.audioButton.isSelected = true
                }
            } catch {
                DispatchQueue.main.async {
                    self.audioButton.setTitle("播放音訊", for: .normal)
                    self.audioButton.isSelected = false
                }
                print("無法播放音訊: \(error.localizedDescription)")
            }
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

extension ChatTableViewCell: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.audioButton.setTitle("播放音訊", for: .normal)
            self?.audioButton.isSelected = false
        }
    }
}
