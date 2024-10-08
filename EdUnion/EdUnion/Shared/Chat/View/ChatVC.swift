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

//class ChatVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate, UIGestureRecognizerDelegate {
//    
//    private var viewModel: ChatViewModel!
//    private let tableView = UITableView()
//    
//    var teacher: Teacher?
//    var student: Student?
//    let userID = UserSession.shared.currentUserID
//    var userRole: String = UserDefaults.standard.string(forKey: "userRole") ?? "teacher"
//    
//    private let imageView = UIImageView()
//    private let messageInputBar = UIView()
//    private let messageTextView = UITextView()
//    private let sendButton = UIButton(type: .system)
//    private let photoButton = UIButton(type: .system)
//    private let recordButton = UIButton(type: .system)
//    
//    private var audioRecorder: AVAudioRecorder?
//    private var recordingSession: AVAudioSession!
//    private var audioFilename: URL?
//    
//    private var bottomConstraint: NSLayoutConstraint!
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        view.backgroundColor = .myBackground
//        setupNavigationBar()
//        setupMessageInputBar()
//        setupTableView()
//        setupRecordingSession()
//        setupKeyboardNotifications()
//        
//        if userRole == "teacher" {
//            viewModel = ChatViewModel(chatRoomID: (userID ?? "") + "_" + (student?.id ?? ""))
//        } else {
//            viewModel = ChatViewModel(chatRoomID: (teacher?.id ?? "") + "_" + (userID ?? ""))
//        }
//        
//        viewModel.onMessagesUpdated = { [weak self] in
//            self?.tableView.reloadData()
//            self?.scrollToBottom()
//        }
//        
//        messageTextView.delegate = self
//    }
//    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        
//        IQKeyboardManager.shared.enable = false
//        setupKeyboardDismissRecognizer()
//        tabBarController?.tabBar.isHidden = true
//        if let tabBarController = self.tabBarController as? TabBarController {
//            tabBarController.setCustomTabBarHidden(true, animated: true)
//        }
//    }
//    
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        
//        IQKeyboardManager.shared.enable = true
//        
//        if self.isMovingFromParent {
//            if let chatListVC = navigationController?.viewControllers.first(where: { $0 is ChatListVC }) {
//                navigationController?.popToViewController(chatListVC, animated: true)
//            }
//        }
//        
//        if let tabBarController = self.tabBarController as? TabBarController {
//            tabBarController.setCustomTabBarHidden(false, animated: true)
//        }
//    }
//    
//    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//        sendMessage()
//        return true
//    }
//    
//    private func setupKeyboardNotifications() {
//        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
//    }
//    
//    private func setupNavigationBar() {
//        
//        if UserDefaults.standard.string(forKey: "userRole") == "teacher" {
//            if let photoURLString = student?.photoURL, let photoURL = URL(string: photoURLString) {
//                imageView.kf.setImage(
//                    with: photoURL,
//                    placeholder: UIImage(systemName: "person.crop.circle.fill")
//                )
//            } else {
//                imageView.image = UIImage(systemName: "person.crop.circle.fill")
//            }
//        } else {
//            if let photoURLString = teacher?.photoURL, let photoURL = URL(string: photoURLString) {
//                imageView.kf.setImage(
//                    with: photoURL,
//                    placeholder: UIImage(systemName: "person.crop.circle.fill")
//                )
//            } else {
//                imageView.image = UIImage(systemName: "person.crop.circle.fill")
//            }
//        }
//        imageView.tintColor = .myMessageCell
//        imageView.contentMode = .scaleAspectFill
//        imageView.layer.cornerRadius = 20
//        imageView.layer.masksToBounds = true
//        imageView.translatesAutoresizingMaskIntoConstraints = false
//        
//        let containerView = UIView()
//        containerView.addSubview(imageView)
//        
//        NSLayoutConstraint.activate([
//            imageView.widthAnchor.constraint(equalToConstant: 40),
//            imageView.heightAnchor.constraint(equalToConstant: 40),
//            imageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
//            imageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
//        ])
//        
//        containerView.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
//        
//        navigationItem.titleView = containerView
//    }
//    
//    private func setupMessageInputBar() {
//        messageTextView.inputAccessoryView = nil
//        messageInputBar.backgroundColor = .myBackground
//        
//        messageTextView.font = UIFont.systemFont(ofSize: 16)
//        messageTextView.layer.borderWidth = 1.0
//        messageTextView.layer.borderColor = UIColor.myGray.cgColor
//        messageTextView.layer.cornerRadius = 10
//        messageTextView.isScrollEnabled = false
//        messageTextView.translatesAutoresizingMaskIntoConstraints = false
//        messageTextView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 32)
//        
//        sendButton.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
//        sendButton.tintColor = .mainOrange
//        sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
//        sendButton.translatesAutoresizingMaskIntoConstraints = false
//        sendButton.isHidden = true
//        
//        photoButton.setImage(UIImage(systemName: "photo"), for: .normal)
//        photoButton.tintColor = .mainOrange
//        photoButton.addTarget(self, action: #selector(selectPhoto), for: .touchUpInside)
//        photoButton.translatesAutoresizingMaskIntoConstraints = false
//        
//        recordButton.setImage(UIImage(systemName: "mic"), for: .normal)
//        recordButton.tintColor = .mainOrange
//        recordButton.addTarget(self, action: #selector(recordTapped), for: .touchUpInside)
//        recordButton.translatesAutoresizingMaskIntoConstraints = false
//        
//        messageInputBar.addSubview(messageTextView)
//        messageInputBar.addSubview(sendButton)
//        messageInputBar.addSubview(photoButton)
//        messageInputBar.addSubview(recordButton)
//        messageInputBar.translatesAutoresizingMaskIntoConstraints = false
//        
//        view.addSubview(messageInputBar)
//        bottomConstraint = messageInputBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
//        
//        NSLayoutConstraint.activate([
//            bottomConstraint,
//            
//            messageInputBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            messageInputBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            
//            photoButton.leadingAnchor.constraint(equalTo: messageInputBar.leadingAnchor, constant: 16),
//            photoButton.centerYAnchor.constraint(equalTo: messageInputBar.centerYAnchor),
//            
//            messageTextView.leadingAnchor.constraint(equalTo: messageInputBar.leadingAnchor, constant: 56),
//            //            messageTextView.centerYAnchor.constraint(equalTo: messageInputBar.centerYAnchor),
//            messageTextView.trailingAnchor.constraint(equalTo: messageInputBar.trailingAnchor, constant: -16),
//            messageTextView.topAnchor.constraint(equalTo: messageInputBar.topAnchor, constant: 8),
//            messageTextView.bottomAnchor.constraint(equalTo: messageInputBar.bottomAnchor, constant: -8),
//            
//            
//            sendButton.trailingAnchor.constraint(equalTo: messageTextView.trailingAnchor, constant: -8),
//            sendButton.centerYAnchor.constraint(equalTo: messageInputBar.centerYAnchor),
//            
//            recordButton.trailingAnchor.constraint(equalTo: messageTextView.trailingAnchor, constant: -8),
//            recordButton.centerYAnchor.constraint(equalTo: messageInputBar.centerYAnchor)
//        ])
//    }
//    
//    private func setupTableView() {
//        tableView.delegate = self
//        tableView.dataSource = self
//        tableView.register(ChatTableViewCell.self, forCellReuseIdentifier: "ChatCell")
//        tableView.separatorStyle = .none
//        tableView.allowsSelection = false
//        tableView.backgroundColor = .clear
//        
//        view.addSubview(tableView)
//        tableView.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
//            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            tableView.bottomAnchor.constraint(equalTo: messageInputBar.topAnchor)
//        ])
//    }
//    
//
//    
//    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
//        if let view = touch.view, view.isDescendant(of: sendButton) {
//            return false
//        }
//        return true
//    }
//    
//    
//    private func setupRecordingSession() {
//        recordingSession = AVAudioSession.sharedInstance()
//        
//        do {
//            try recordingSession.setCategory(.playAndRecord, mode: .default)
//            try recordingSession.setActive(true)
//            
//            recordingSession.requestRecordPermission { [weak self] allowed in
//                DispatchQueue.main.async {
//                    if allowed {
//                        self?.recordButton.isEnabled = true
//                    } else {
//                        self?.recordButton.isEnabled = false
//                        print("錄音權限被拒絕")
//                    }
//                }
//            }
//        } catch {
//            print("無法設置錄音會話: \(error.localizedDescription)")
//        }
//    }
//    
//    private func scrollToBottom() {
//        if viewModel.numberOfMessages() > 0 {
//            let indexPath = IndexPath(row: viewModel.numberOfMessages() - 1, section: 0)
//            tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
//        }
//    }
//    
//    private func startRecording() {
//        audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
//        
//        let settings = [
//            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
//            AVSampleRateKey: 12000,
//            AVNumberOfChannelsKey: 1,
//            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
//        ]
//        
//        do {
//            audioRecorder = try AVAudioRecorder(url: audioFilename!, settings: settings)
//            audioRecorder?.record()
//        } catch {
//            finishRecording(success: false)
//            print("無法開始錄音: \(error.localizedDescription)")
//        }
//    }
//    
//    private func finishRecording(success: Bool) {
//        audioRecorder?.stop()
//        audioRecorder = nil
//        
//        if success, let audioFilename = audioFilename {
//            do {
//                let audioData = try Data(contentsOf: audioFilename)
//                viewModel.sendAudioMessage(audioData)
//            } catch {
//                print("無法讀取錄音檔案: \(error.localizedDescription)")
//            }
//        } else {
//            print("錄音失敗")
//        }
//    }
//    
//    private func getDocumentsDirectory() -> URL {
//        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
//    }
//    
//    @objc private func selectPhoto() {
//        let imagePickerController = UIImagePickerController()
//        imagePickerController.delegate = self
//        imagePickerController.sourceType = .photoLibrary
//        present(imagePickerController, animated: true, completion: nil)
//    }
//    
//    @objc private func sendMessage() {
//        guard let messageText = messageTextView.text, !messageText.isEmpty else {
//            return
//        }
//        
//        viewModel.sendMessage(messageText)
//        messageTextView.text = nil
//    }
//    
//    @objc private func recordTapped() {
//        if audioRecorder == nil {
//            startRecording()
//            recordButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
//        } else {
//            finishRecording(success: true)
//            recordButton.setImage(UIImage(systemName: "mic"), for: .normal)
//        }
//    }
//    
//    @objc private func textFieldDidChange() {
//        if let text = messageTextView.text, !text.isEmpty {
//            sendButton.isHidden = false
//            recordButton.isHidden = true
//        } else {
//            sendButton.isHidden = true
//            recordButton.isHidden = false
//        }
//    }
//    
//    @objc private func handleKeyboardWillShow(notification: NSNotification) {
//        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
//            let keyboardHeight = keyboardFrame.height
//            
//            UIView.animate(withDuration: 0.3) {
//                self.bottomConstraint.constant = -keyboardHeight + self.view.safeAreaInsets.bottom
//                self.view.layoutIfNeeded()
//            }
//            
//            scrollToBottom()
//        }
//    }
//    
//    @objc private func handleKeyboardWillHide(notification: NSNotification) {
//        UIView.animate(withDuration: 0.3) {
//            self.bottomConstraint.constant = 0
//            self.view.layoutIfNeeded()
//        }
//        
////        tableView.contentInset.bottom = 0
////        tableView.scrollIndicatorInsets.bottom = 0
//    }
//    
//    // MARK: - TableView Delegate
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return viewModel.numberOfMessages()
//    }
//    
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        
//        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell", for: indexPath) as! ChatTableViewCell
//        cell.backgroundColor = .myBackground
//        let message = viewModel.message(at: indexPath.row)
//        let previousMessage: Message? = indexPath.row > 0 ? viewModel.message(at: indexPath.row - 1) : nil
//        let pendingImage = viewModel.getPendingImage(for: message.ID ?? "nil")
//        cell.configure(with: message, previousMessage: previousMessage, image: pendingImage)
//        cell.delegate = self
//        return cell
//    }
//    
//    // MARK: - ImagePicker Delegate
//    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
//        if let selectedImage = info[.originalImage] as? UIImage {
//            viewModel.sendPhotoMessage(selectedImage)
//        }
//        dismiss(animated: true, completion: nil)
//    }
//    
//    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
//        dismiss(animated: true, completion: nil)
//    }
//    
//    @objc private func backToChatList() {
//        if let chatListVC = navigationController?.viewControllers.first(where: { $0 is ChatListVC }) {
//            navigationController?.popToViewController(chatListVC, animated: true)
//        }
//    }
//    
//    func textViewDidChange(_ textView: UITextView) {
//        let size = textView.sizeThatFits(CGSize(width: textView.frame.width, height: CGFloat.greatestFiniteMagnitude))
//        
//        let maxHeight: CGFloat = 100
//        let newHeight = min(size.height, maxHeight)
//        
//        if newHeight != messageInputBar.frame.height {
//            UIView.animate(withDuration: 0.2) {
//                self.messageInputBar.frame.size.height = newHeight + 16
//                self.view.layoutIfNeeded()
//            }
//        }
//        
//        if let text = textView.text, !text.isEmpty {
//            sendButton.isHidden = false
//            recordButton.isHidden = true
//        } else {
//            sendButton.isHidden = true
//            recordButton.isHidden = false
//        }
//    }
//}
//
//extension ChatVC: ChatTableViewCellDelegate {
//    func chatTableViewCell(_ cell: ChatTableViewCell, didTapImage image: UIImage) {
//        let fullScreenVC = FullScreenImageVC(image: image)
//        present(fullScreenVC, animated: true, completion: nil)
//    }
//    
//}
//

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
        
        if userRole == "teacher" {
            viewModel = ChatViewModel(chatRoomID: (userID ?? "") + "_" + (student?.id ?? ""))
        } else {
            viewModel = ChatViewModel(chatRoomID: (teacher?.id ?? "") + "_" + (userID ?? ""))
        }
        
        viewModel.onMessagesUpdated = { [weak self] in
            self?.tableView.reloadData()
            self?.scrollToBottom()
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
        
        if let tabBarController = self.tabBarController as? TabBarController {
            tabBarController.setCustomTabBarHidden(false, animated: true)
        }
    }
    
    private func updateSendButtonState() {
        if let text = messageTextView.text, !text.isEmpty {
            sendButton.isEnabled = true
            sendButton.tintColor = .mainOrange // 啟用時的顏色
        } else {
            sendButton.isEnabled = false
            sendButton.tintColor = .gray // 禁用時的顏色
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendMessage()
        return true
    }
    
    private func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func setupNavigationBar() {
        
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
        photoButton.tintColor = .mainOrange
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
            sendButton.centerYAnchor.constraint(equalTo: messageInputBar.centerYAnchor),
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
    }
    
//    @objc private func textFieldDidChange() {
//        let size = textView.sizeThatFits(CGSize(width: textView.frame.width, height: CGFloat.greatestFiniteMagnitude))
//            
//            let maxHeight: CGFloat = 100
//            let newHeight = min(size.height, maxHeight)
//            
//            if newHeight != messageInputBar.frame.height {
//                UIView.animate(withDuration: 0.2) {
//                    self.messageInputBar.frame.size.height = newHeight + 16
//                    self.view.layoutIfNeeded()
//                }
//            }
//            
//            // 更新 sendButton 狀態
//            updateSendButtonState()
//    }
    
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

        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell", for: indexPath) as! ChatTableViewCell
        cell.backgroundColor = .myBackground
        let message = viewModel.message(at: indexPath.row)
        let previousMessage: Message? = indexPath.row > 0 ? viewModel.message(at: indexPath.row - 1) : nil
        let pendingImage = viewModel.getPendingImage(for: message.ID ?? "nil")
        cell.configure(with: message, previousMessage: previousMessage, image: pendingImage)
        cell.delegate = self
        return cell
    }
    
    // MARK: - ImagePicker Delegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
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
