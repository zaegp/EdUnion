//
//  ChatVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/11.
//

import UIKit
import AVFoundation

class ChatVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private var audioRecorder: AVAudioRecorder?
    private var recordingSession: AVAudioSession!
    private var audioFilename: URL?
    
    private let tableView = UITableView()
    private let messageInputBar = UIView()
    private let messageTextField = UITextField()
    private let sendButton = UIButton(type: .system)
    private let photoButton = UIButton(type: .system)
    private let recordButton = UIButton(type: .system)
    
    private var viewModel: ChatViewModel!
    
    init(chatRoomID: String, currentUserID: String) {
        super.init(nibName: nil, bundle: nil)
        viewModel = ChatViewModel(chatRoomID: chatRoomID, currentUserID: currentUserID)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Chat"
        
        setupMessageInputBar()
        setupTableView()
        setupRecordingSession()
        
        viewModel.onMessagesUpdated = { [weak self] in
            self?.tableView.reloadData()
            self?.scrollToBottom()
        }
        
        // 鍵盤出現時調整視圖
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func setupRecordingSession() {
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            
            // 請求錄音權限
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
    
    // 設置 TableView
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ChatTableViewCell.self, forCellReuseIdentifier: "ChatCell")
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: messageInputBar.topAnchor)
        ])
    }
    
    // 設置 Message Input Bar
    private func setupMessageInputBar() {
        messageInputBar.backgroundColor = .systemGray5
        
        messageTextField.placeholder = "Enter message..."
        messageTextField.borderStyle = .roundedRect
        messageTextField.translatesAutoresizingMaskIntoConstraints = false
        
        sendButton.setTitle("Send", for: .normal)
        sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        
        photoButton.setImage(UIImage(systemName: "photo"), for: .normal)
        photoButton.addTarget(self, action: #selector(selectPhoto), for: .touchUpInside)
        photoButton.translatesAutoresizingMaskIntoConstraints = false
        
        recordButton.setTitle("Record", for: .normal)  // 設置錄音按鈕
        recordButton.addTarget(self, action: #selector(recordTapped), for: .touchUpInside)
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        
        messageInputBar.addSubview(messageTextField)
        messageInputBar.addSubview(sendButton)
        messageInputBar.addSubview(photoButton)
        messageInputBar.addSubview(recordButton)  // 添加錄音按鈕
        
        view.addSubview(messageInputBar)
        messageInputBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            messageInputBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            messageInputBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            messageInputBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            messageInputBar.heightAnchor.constraint(equalToConstant: 50),
            
            messageTextField.leadingAnchor.constraint(equalTo: messageInputBar.leadingAnchor, constant: 8),
            messageTextField.centerYAnchor.constraint(equalTo: messageInputBar.centerYAnchor),
            messageTextField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            messageTextField.heightAnchor.constraint(equalToConstant: 35),
            
            sendButton.trailingAnchor.constraint(equalTo: messageInputBar.trailingAnchor, constant: -8),
            sendButton.centerYAnchor.constraint(equalTo: messageInputBar.centerYAnchor),
            
            photoButton.leadingAnchor.constraint(equalTo: messageInputBar.leadingAnchor, constant: 8),
            photoButton.centerYAnchor.constraint(equalTo: messageInputBar.centerYAnchor),
            
            recordButton.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            recordButton.centerYAnchor.constraint(equalTo: messageInputBar.centerYAnchor)
        ])
    }
    
    // 發送訊息
    @objc private func sendMessage() {
        guard let messageText = messageTextField.text, !messageText.isEmpty else {
            return
        }
        
        // 通知 ViewModel 發送訊息
        viewModel.sendMessage(messageText)
        messageTextField.text = nil
    }
    
    // 自動滾動到底部
    private func scrollToBottom() {
        if viewModel.numberOfMessages() > 0 {
            let indexPath = IndexPath(row: viewModel.numberOfMessages() - 1, section: 0)
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
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
    
    // MARK: - UITableViewDelegate, UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfMessages()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell", for: indexPath) as! ChatTableViewCell
        let message = viewModel.message(at: indexPath.row)
        cell.configure(with: message)
        return cell
    }
    
    @objc private func selectPhoto() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .photoLibrary
        present(imagePickerController, animated: true, completion: nil)
    }
    
    @objc private func recordTapped() {
        if audioRecorder == nil {
            startRecording()
            recordButton.setTitle("Stop", for: .normal)
        } else {
            finishRecording(success: true)
            recordButton.setTitle("Record", for: .normal)
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
                viewModel.sendAudioMessage(audioData) // 傳送音訊
            } catch {
                print("無法讀取錄音檔案: \(error.localizedDescription)")
            }
        } else {
            print("錄音失敗")
        }
    }
    
    // 獲取文件路徑
    private func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

extension ChatVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            // 將圖片發送到 ViewModel 並上傳到 Firebase
            viewModel.sendPhotoMessage(selectedImage)
        }
        dismiss(animated: true, completion: nil)
    }
}
