//
//  ChatTableViewCell.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/11.
//

import UIKit
import AVFoundation
import Kingfisher

class ChatTableViewCell: UITableViewCell {
    
    private let messageLabel = UILabel()
    private let bubbleBackgroundView = UIView()
    private let timestampLabel = UILabel()
    private var audioPlayer: AVAudioPlayer?
    private var message: Message?
    private let messageImageView = UIImageView()
    private let audioButton = UIButton(type: .system)
    private var imageHeightConstraint: NSLayoutConstraint?
    
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
        bubbleBackgroundView.addSubview(messageLabel)
        
        messageImageView.contentMode = .scaleAspectFill
        messageImageView.clipsToBounds = true
        messageImageView.translatesAutoresizingMaskIntoConstraints = false
        bubbleBackgroundView.addSubview(messageImageView)
        
        audioButton.setTitle("Play Audio", for: .normal)
        audioButton.addTarget(self, action: #selector(playAudio), for: .touchUpInside)
        audioButton.translatesAutoresizingMaskIntoConstraints = false
        bubbleBackgroundView.addSubview(audioButton)
        
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
            super.prepareForReuse()
            // Reset content
            messageLabel.text = nil
            messageImageView.image = nil
            audioPlayer = nil
            message = nil
            
            // Reset visibility
            messageLabel.isHidden = true
            messageImageView.isHidden = true
            audioButton.isHidden = true
            
            // Deactivate constraints
            imageHeightConstraint?.isActive = false
        }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            bubbleBackgroundView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 60),
            bubbleBackgroundView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -60),
            bubbleBackgroundView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            bubbleBackgroundView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
        ])
        
        let stackView = UIStackView(arrangedSubviews: [messageLabel, messageImageView, audioButton])
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        bubbleBackgroundView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: bubbleBackgroundView.topAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: bubbleBackgroundView.bottomAnchor, constant: -8),
            stackView.leadingAnchor.constraint(equalTo: bubbleBackgroundView.leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: bubbleBackgroundView.trailingAnchor, constant: -8),
        ])
        
        imageHeightConstraint = messageImageView.heightAnchor.constraint(equalToConstant: 150)
    }
    
    func configure(with message: Message) {
        self.message = message
        messageLabel.isHidden = true
        messageImageView.isHidden = true
        audioButton.isHidden = true
        
        imageHeightConstraint?.isActive = false
        
        if let text = message.text, !text.isEmpty {
            messageLabel.text = text
            messageLabel.isHidden = false
        } else if let imageURL = message.imageURL {
            imageHeightConstraint?.isActive = true
            messageImageView.isHidden = false
            loadImage(from: imageURL)
        } else if let _ = message.audioURL {
            audioButton.isHidden = false
        }
        
        isSentByCurrentUser = message.isSentByCurrentUser
    }

    private func loadImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: url),
               let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.messageImageView.image = image
                }
            }
        }
    }
    
    @objc private func playAudio() {
        guard let audioURLString = message?.audioURL,
              let url = URL(string: audioURLString) else {
            print("音訊 URL 無效")
            return
        }
        
        DispatchQueue.global().async { [weak self] in
            do {
                let audioData = try Data(contentsOf: url)
                self?.audioPlayer = try AVAudioPlayer(data: audioData)
                self?.audioPlayer?.play()
            } catch {
                print("無法播放音訊: \(error.localizedDescription)")
            }
        }
    }
}
