//
//  ChatVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/11.
//

import UIKit
import AVFoundation
import FirebaseStorage
import FirebaseFirestore
import IQKeyboardManagerSwift
import Kingfisher
import FirebaseFunctions

class ChatVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate, UIGestureRecognizerDelegate {
    
    private var viewModel: ChatViewModel!
    private let tableView = UITableView()
    
    var teacher: Teacher?
    var student: Student?
    let userID = UserSession.shared.currentUserID
    var userRole: String = UserDefaults.standard.string(forKey: "userRole") ?? "teacher"
    
    private let imageView = UIImageView()
    private let messageInputBar = UIView()
    private let messageTextView = UITextView()
    private let sendButton = UIButton(type: .system)
    private let photoButton = UIButton(type: .system)
    
    private var bottomConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .myBackground
        setupNavigationBar()
        setupMessageInputBar()
        setupTableView()
        setupKeyboardNotifications()
        updateSendButtonState()
        enableSwipeToGoBack()
        
        if userRole == "teacher" {
            viewModel = ChatViewModel(chatRoomID: (userID ?? "") + "_" + (student?.id ?? ""))
        } else {
            viewModel = ChatViewModel(chatRoomID: (teacher?.id ?? "") + "_" + (userID ?? ""))
        }
        
        viewModel.onMessagesUpdated = { [weak self] in
            self?.tableView.reloadData()
            self?.scrollToBottom()
            self?.messageTextView.becomeFirstResponder()
        }
        
        messageTextView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        IQKeyboardManager.shared.enable = false
        setupKeyboardDismissRecognizer()
        tabBarController?.tabBar.isHidden = true
        if let tabBarController = self.tabBarController as? TabBarController {
            tabBarController.setCustomTabBarHidden(true, animated: true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        IQKeyboardManager.shared.enable = true
        
        if self.isMovingFromParent {
            if let chatListVC = navigationController?.viewControllers.first(where: { $0 is ChatListVC }) {
                navigationController?.popToViewController(chatListVC, animated: true)
            }
        }
    }
    
    private func updateSendButtonState() {
        if let text = messageTextView.text, !text.isEmpty {
            sendButton.isEnabled = true
            sendButton.tintColor = .mainOrange
        } else {
            sendButton.isEnabled = false
            sendButton.tintColor = .gray
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendMessage()
        return true
    }
    
    private func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardWillShow(notification:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardWillHide(notification:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    private func setupNavigationBar() {
        
        let videoCallButton = UIBarButtonItem(
            image: UIImage(systemName: "video"),
            style: .plain,
            target: self,
            action: #selector(videoCallButtonTapped)
        )
        videoCallButton.tintColor = .mainOrange
        
        navigationItem.rightBarButtonItem = videoCallButton
        
        if UserDefaults.standard.string(forKey: "userRole") == "teacher" {
            if let photoURLString = student?.photoURL, let photoURL = URL(string: photoURLString) {
                imageView.kf.setImage(
                    with: photoURL,
                    placeholder: UIImage(systemName: "person.crop.circle.fill")
                )
            } else {
                imageView.image = UIImage(systemName: "person.crop.circle.fill")
            }
        } else {
            if let photoURLString = teacher?.photoURL, let photoURL = URL(string: photoURLString) {
                imageView.kf.setImage(
                    with: photoURL,
                    placeholder: UIImage(systemName: "person.crop.circle.fill")
                )
            } else {
                imageView.image = UIImage(systemName: "person.crop.circle.fill")
            }
        }
        imageView.tintColor = .myMessageCell
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 20
        imageView.layer.masksToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        let containerView = UIView()
        containerView.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 40),
            imageView.heightAnchor.constraint(equalToConstant: 40),
            imageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
        
        containerView.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        
        navigationItem.titleView = containerView
    }
    
    @objc private func videoCallButtonTapped() {
        print("視訊按鈕被點擊")
        let videoCallVC = VideoCallVC()
        
        videoCallVC.channelName = viewModel.chatRoomID
        
        videoCallVC.modalPresentationStyle = .fullScreen
        videoCallVC.onCallEnded = { [weak self] in
            guard let self = self else { return }
            self.viewModel.addVideoCallMessage() 
        }
        
        present(videoCallVC, animated: true, completion: {
            print("成功呈現 VideoCallVC")
        })
    }
    
    private func setupMessageInputBar() {
        messageTextView.inputAccessoryView = nil
        messageInputBar.backgroundColor = .myBackground
        
        messageTextView.font = UIFont.systemFont(ofSize: 16)
        messageTextView.layer.borderWidth = 1.0
        messageTextView.layer.borderColor = UIColor.myGray.cgColor
        messageTextView.layer.cornerRadius = 10
        messageTextView.isScrollEnabled = false
        messageTextView.translatesAutoresizingMaskIntoConstraints = false
        messageTextView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 32)
        
        sendButton.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
        sendButton.tintColor = .mainOrange
        sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        
        photoButton.setImage(UIImage(systemName: "photo"), for: .normal)
        photoButton.tintColor = .myMessageCell
        photoButton.addTarget(self, action: #selector(selectPhoto), for: .touchUpInside)
        photoButton.translatesAutoresizingMaskIntoConstraints = false
        
        messageInputBar.addSubview(messageTextView)
        messageInputBar.addSubview(sendButton)
        messageInputBar.addSubview(photoButton)
        messageInputBar.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(messageInputBar)
        bottomConstraint = messageInputBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        
        NSLayoutConstraint.activate([
            bottomConstraint,
            
            messageInputBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            messageInputBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            photoButton.leadingAnchor.constraint(equalTo: messageInputBar.leadingAnchor, constant: 16),
            photoButton.centerYAnchor.constraint(equalTo: messageInputBar.centerYAnchor),
            
            messageTextView.leadingAnchor.constraint(equalTo: messageInputBar.leadingAnchor, constant: 56),
            messageTextView.trailingAnchor.constraint(equalTo: messageInputBar.trailingAnchor, constant: -16),
            messageTextView.topAnchor.constraint(equalTo: messageInputBar.topAnchor, constant: 8),
            messageTextView.bottomAnchor.constraint(equalTo: messageInputBar.bottomAnchor, constant: -8),
            
            sendButton.trailingAnchor.constraint(equalTo: messageTextView.trailingAnchor, constant: -8),
            sendButton.centerYAnchor.constraint(equalTo: messageInputBar.centerYAnchor)
        ])
    }
    
    private func scrollToBottom() {
        if viewModel.numberOfMessages() > 0 {
            let indexPath = IndexPath(row: viewModel.numberOfMessages() - 1, section: 0)
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
    
    @objc private func selectPhoto() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .photoLibrary
        present(imagePickerController, animated: true, completion: nil)
    }
    
    @objc private func sendMessage() {
        guard let messageText = messageTextView.text, !messageText.isEmpty else {
            return
        }
        
        viewModel.sendMessage(messageText)
        messageTextView.text = nil
        updateSendButtonState()
        messageTextView.becomeFirstResponder() 
    }
    
    @objc private func handleKeyboardWillShow(notification: NSNotification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let keyboardHeight = keyboardFrame.height
            
            UIView.animate(withDuration: 0.3) {
                self.bottomConstraint.constant = -keyboardHeight + self.view.safeAreaInsets.bottom
                self.view.layoutIfNeeded()
            }
            
            scrollToBottom()
        }
    }
    
    @objc private func handleKeyboardWillHide(notification: NSNotification) {
        UIView.animate(withDuration: 0.3) {
            self.bottomConstraint.constant = 0
            self.view.layoutIfNeeded()
        }
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ChatTableViewCell.self, forCellReuseIdentifier: "ChatCell")
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.backgroundColor = .clear
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: messageInputBar.topAnchor)
        ])
    }
    
    @objc private func backToChatList() {
        if let chatListVC = navigationController?.viewControllers.first(where: { $0 is ChatListVC }) {
            navigationController?.popToViewController(chatListVC, animated: true)
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        let size = textView.sizeThatFits(CGSize(width: textView.frame.width, height: CGFloat.greatestFiniteMagnitude))
        
        let maxHeight: CGFloat = 100
        let newHeight = min(size.height, maxHeight)
        
        if newHeight != messageInputBar.frame.height {
            UIView.animate(withDuration: 0.2) {
                self.messageInputBar.frame.size.height = newHeight + 16
                self.view.layoutIfNeeded()
            }
        }
        
        updateSendButtonState()
    }
    
    // MARK: - TableView Delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfMessages()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell: ChatTableViewCell = tableView.dequeueReusableCell(withIdentifier: "ChatCell", for: indexPath)
        cell.backgroundColor = .myBackground
        let message = viewModel.message(at: indexPath.row)
        let previousMessage: Message? = indexPath.row > 0 ? viewModel.message(at: indexPath.row - 1) : nil
        let pendingImage = viewModel.getPendingImage(for: message.ID ?? "nil")
        cell.configure(with: message, previousMessage: previousMessage, image: pendingImage)
        cell.delegate = self
        return cell
    }
    
    // MARK: - ImagePicker Delegate
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        if let selectedImage = info[.originalImage] as? UIImage {
            viewModel.sendPhotoMessage(selectedImage)
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}

extension ChatVC: ChatTableViewCellDelegate {
    func chatTableViewCell(_ cell: ChatTableViewCell, didTapImage image: UIImage) {
        let fullScreenVC = FullScreenImageVC(image: image)
        present(fullScreenVC, animated: true, completion: nil)
    }
}
