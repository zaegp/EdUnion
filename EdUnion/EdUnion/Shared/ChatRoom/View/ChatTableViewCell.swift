//
//  ChatTableViewCell.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/11.
//

import UIKit
import AVFoundation

class ChatTableViewCell: UITableViewCell {
    
    private let messageLabel = UILabel()
    private let bubbleBackgroundView = UIView()
    private let timestampLabel = UILabel()
    private var audioPlayer: AVAudioPlayer?
    private var message: Message?
    private let messageImageView = UIImageView() // 顯示圖片
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
        addSubview(messageLabel)
        
        messageImageView.contentMode = .scaleAspectFill
        messageImageView.clipsToBounds = true
        messageImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(messageImageView)
        
        audioButton.setTitle("Play Audio", for: .normal)
        audioButton.addTarget(self, action: #selector(playAudio), for: .touchUpInside)
        audioButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(audioButton)
        
        // 添加布局约束
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // 根據內容自適應寬度，保證消息泡泡能正確顯示
            bubbleBackgroundView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 60),
            bubbleBackgroundView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -60),
            
            bubbleBackgroundView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            bubbleBackgroundView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            
            // 消息文字的約束
            messageLabel.topAnchor.constraint(equalTo: bubbleBackgroundView.topAnchor, constant: 8),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleBackgroundView.bottomAnchor, constant: -8),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleBackgroundView.leadingAnchor, constant: 8),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleBackgroundView.trailingAnchor, constant: -8),
            
            // 圖片的約束，讓圖片高度固定，並且自適應寬度
            messageImageView.topAnchor.constraint(equalTo: bubbleBackgroundView.topAnchor, constant: 8),
            messageImageView.bottomAnchor.constraint(equalTo: bubbleBackgroundView.bottomAnchor, constant: -8),
            messageImageView.leadingAnchor.constraint(equalTo: bubbleBackgroundView.leadingAnchor, constant: 8),
            messageImageView.trailingAnchor.constraint(equalTo: bubbleBackgroundView.trailingAnchor, constant: -8),
            messageImageView.heightAnchor.constraint(lessThanOrEqualToConstant: 150),
            
            audioButton.centerXAnchor.constraint(equalTo: bubbleBackgroundView.centerXAnchor),
            audioButton.centerYAnchor.constraint(equalTo: bubbleBackgroundView.centerYAnchor)
        ])
        
        imageHeightConstraint = messageImageView.heightAnchor.constraint(equalToConstant: 150)
                imageHeightConstraint?.isActive = false  // 默認不激活
    }
    
    func configure(with message: Message) {
        print(message)
        // 清空狀態，避免重用時出現錯誤
        messageLabel.isHidden = true
        messageImageView.isHidden = true
        audioButton.isHidden = true
        
        // 根據消息內容決定顯示什麼
        if let text = message.text, !text.isEmpty  {
            messageLabel.text = text
            messageLabel.isHidden = false
            imageHeightConstraint?.isActive = false
        } else if let imageURL = message.imageURL {
            imageHeightConstraint?.isActive = true
            messageImageView.isHidden = false
            loadImage(from: imageURL)
        } else if let _ = message.audioURL {
            // 顯示語音按鈕
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
        guard let audioURLString = message?.audioURL, // 假設 message 有 audioURL 屬性
              let url = URL(string: audioURLString) else {
            print("音訊 URL 無效")
            return
        }
        
        // 在背景線程下載音訊檔案並播放
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
