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


class ChatVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    private var viewModel: ChatViewModel!
    private let tableView = UITableView()
    
    var teacherID: String = ""  // 從 TeacherDetailVC 傳遞
    var studentID: String = ""
    
    private let messageInputBar = UIView()
    private let messageTextField = UITextField()
    private let sendButton = UIButton(type: .system)
    private let photoButton = UIButton(type: .system)
    private let recordButton = UIButton(type: .system)
    
    private var audioRecorder: AVAudioRecorder?
    private var recordingSession: AVAudioSession!
    private var audioFilename: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        tabBarController?.tabBar.isHidden = true
        
        setupNavigationBar()
        setupMessageInputBar()
        setupTableView()
        setupRecordingSession()
        
        viewModel = ChatViewModel(chatRoomID: teacherID + "_" + studentID, currentUserID: studentID, otherParticipantID: teacherID)
        
        viewModel.onMessagesUpdated = { [weak self] in
            self?.tableView.reloadData()
            self?.scrollToBottom()
        }
        
        messageTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
//        self.navigationItem.hidesBackButton = true
           
           // 添加自定義的 back 按鈕
//           let customBackButton = UIBarButtonItem(title: "Back to Chat List", style: .plain, target: self, action: #selector(backToChatList))
//           self.navigationItem.leftBarButtonItem = customBackButton
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.isMovingFromParent {
            // 如果是因為點擊返回按鈕而觸發的
            if let chatListVC = navigationController?.viewControllers.first(where: { $0 is ChatListVC }) {
                navigationController?.popToViewController(chatListVC, animated: true)
            }
        }
    }
    
    private func setupNavigationBar() {
        let imageView = UIImageView(image: UIImage(systemName: "person.circle"))
        
        imageView.contentMode = .scaleAspectFit
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
        messageInputBar.backgroundColor = .white
        
        messageTextField.placeholder = "Message"
        messageTextField.borderStyle = .roundedRect
        messageTextField.translatesAutoresizingMaskIntoConstraints = false
        
        sendButton.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        sendButton.tintColor = .mainOrange
        sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.isHidden = true
        
        photoButton.setImage(UIImage(systemName: "photo"), for: .normal)
        photoButton.tintColor = .mainOrange
        photoButton.addTarget(self, action: #selector(selectPhoto), for: .touchUpInside)
        photoButton.translatesAutoresizingMaskIntoConstraints = false
        
        recordButton.setImage(UIImage(systemName: "mic"), for: .normal)
        recordButton.tintColor = .mainOrange
        recordButton.addTarget(self, action: #selector(recordTapped), for: .touchUpInside)
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        
        messageInputBar.addSubview(messageTextField)
        messageInputBar.addSubview(sendButton)
        messageInputBar.addSubview(photoButton)
        messageInputBar.addSubview(recordButton)
        
        view.addSubview(messageInputBar)
        messageInputBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            messageInputBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            messageInputBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            messageInputBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            messageInputBar.heightAnchor.constraint(equalToConstant: 50),
            
            photoButton.leadingAnchor.constraint(equalTo: messageInputBar.leadingAnchor, constant: 16),
            photoButton.centerYAnchor.constraint(equalTo: messageInputBar.centerYAnchor),
            
            messageTextField.leadingAnchor.constraint(equalTo: messageInputBar.leadingAnchor, constant: 56),
            messageTextField.centerYAnchor.constraint(equalTo: messageInputBar.centerYAnchor),
            messageTextField.trailingAnchor.constraint(equalTo: messageInputBar.trailingAnchor, constant: -16),
            messageTextField.heightAnchor.constraint(equalToConstant: 35),
            
            sendButton.trailingAnchor.constraint(equalTo: messageTextField.trailingAnchor, constant: -8),
            sendButton.centerYAnchor.constraint(equalTo: messageInputBar.centerYAnchor),
            
            recordButton.trailingAnchor.constraint(equalTo: messageTextField.trailingAnchor, constant: -8),
            recordButton.centerYAnchor.constraint(equalTo: messageInputBar.centerYAnchor)
        ])
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ChatTableViewCell.self, forCellReuseIdentifier: "ChatCell")
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: messageInputBar.topAnchor)
        ])
    }
    
    private func setupRecordingSession() {
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            
            recordingSession.requestRecordPermission { [weak self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        self?.recordButton.isEnabled = true
                    } else {
                        self?.recordButton.isEnabled = false
                        print("錄音權限被拒絕")
                    }
                }
            }
        } catch {
            print("無法設置錄音會話: \(error.localizedDescription)")
        }
    }
    
    private func scrollToBottom() {
        if viewModel.numberOfMessages() > 0 {
            let indexPath = IndexPath(row: viewModel.numberOfMessages() - 1, section: 0)
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
    
    private func startRecording() {
        audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename!, settings: settings)
            audioRecorder?.record()
        } catch {
            finishRecording(success: false)
            print("無法開始錄音: \(error.localizedDescription)")
        }
    }
    
    private func finishRecording(success: Bool) {
        audioRecorder?.stop()
        audioRecorder = nil
        
        if success, let audioFilename = audioFilename {
            do {
                let audioData = try Data(contentsOf: audioFilename)
                viewModel.sendAudioMessage(audioData) 
            } catch {
                print("無法讀取錄音檔案: \(error.localizedDescription)")
            }
        } else {
            print("錄音失敗")
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    @objc private func selectPhoto() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .photoLibrary
        present(imagePickerController, animated: true, completion: nil)
    }
    
    @objc private func sendMessage() {
        guard let messageText = messageTextField.text, !messageText.isEmpty else {
            return
        }
        
        viewModel.sendMessage(messageText)
        messageTextField.text = nil
    }
    
    @objc private func recordTapped() {
        if audioRecorder == nil {
            startRecording()
            recordButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        } else {
            finishRecording(success: true)
            recordButton.setImage(UIImage(systemName: "mic"), for: .normal)
        }
    }
    
    @objc private func textFieldDidChange() {
        if let text = messageTextField.text, !text.isEmpty {
            sendButton.isHidden = false
            recordButton.isHidden = true
        } else {
            sendButton.isHidden = true
            recordButton.isHidden = false
        }
    }
    
    @objc private func handleKeyboardWillShow(notification: NSNotification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            messageInputBar.frame.origin.y = view.frame.height - keyboardFrame.height - messageInputBar.frame.height
            tableView.contentInset.bottom = keyboardFrame.height
            scrollToBottom()
        }
    }
    
    @objc private func handleKeyboardWillHide(notification: NSNotification) {
        messageInputBar.frame.origin.y = view.frame.height - messageInputBar.frame.height
        tableView.contentInset.bottom = 0
    }
    
    // MARK: - TableView Delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfMessages()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell", for: indexPath) as! ChatTableViewCell
        let message = viewModel.message(at: indexPath.row)
        let previousMessage: Message? = indexPath.row > 0 ? viewModel.message(at: indexPath.row - 1) : nil
        print("1111111")
        print(message)
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
    
    @objc private func backToChatList() {
        if let chatListVC = navigationController?.viewControllers.first(where: { $0 is ChatListVC }) {
            navigationController?.popToViewController(chatListVC, animated: true)
        }
    }
}


extension ChatVC: ChatTableViewCellDelegate {
    func chatTableViewCell(_ cell: ChatTableViewCell, didTapImage image: UIImage) {
        let fullScreenVC = FullScreenImageVC(image: image)
        present(fullScreenVC, animated: true, completion: nil)
    }
    
}
