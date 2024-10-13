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
import AgoraRtcKit
import AgoraUIKit
import FirebaseFunctions
import FirebaseAuth

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
        
        let videoCallButton = UIBarButtonItem(
            image: UIImage(systemName: "video.fill"),
            style: .plain,
            target: self,
            action: #selector(videoCallButtonTapped)
        )
        videoCallButton.tintColor = .black
        
        // 將視訊按鈕添加到導航欄右側
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
                self.viewModel.addVideoCallMessage() // 通話結束後添加消息
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
        updateSendButtonState()
        messageTextView.becomeFirstResponder() // 確保鍵盤保持打開
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

//class VideoCallVC: UIViewController {
//    
//    var agoraKit: AgoraRtcEngineKit!
//    var localVideo: UIView!
//    var remoteVideo: UIView!
//    
//    let appID = "dffc6ad07ded418683e4b403b9ee8be1" // 您的 Agora App ID
//    var channelName: String? // 動態設置頻道名稱
//    var token: String? // 動態獲取的 Token
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        print("VideoCallVC 的 viewDidLoad 被調用")
//        view.backgroundColor = .black
//        setupAgora()
//        setupRemoteVideoView()
//        setupLocalVideoView()
//        setupControlButtons()
//    }
//    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        
//        guard let channelName = channelName, !channelName.isEmpty else {
//            print("頻道名稱未設置")
//            showAlert(message: "頻道名稱未設置")
//            return
//        }
//        
//        joinChannel()
//    }
//    
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        leaveChannel()
//    }
//    
//    private func setupAgora() {
//        print("正在初始化 Agora")
//        agoraKit = AgoraRtcEngineKit.sharedEngine(withAppId: appID, delegate: self)
//        agoraKit.enableVideo()
//        print("Agora 初始化完成")
//    }
//    
//    private func setupLocalVideoView() {
//        localVideo = UIView()
//        localVideo.translatesAutoresizingMaskIntoConstraints = false
//        localVideo.backgroundColor = .darkGray
//        view.addSubview(localVideo)
//        
//        NSLayoutConstraint.activate([
//            localVideo.widthAnchor.constraint(equalToConstant: 120),
//            localVideo.heightAnchor.constraint(equalToConstant: 160),
//            localVideo.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
//            localVideo.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100)
//        ])
//        
//        let videoCanvas = AgoraRtcVideoCanvas()
//        videoCanvas.uid = 0
//        videoCanvas.view = localVideo
//        videoCanvas.renderMode = .hidden
//        agoraKit.setupLocalVideo(videoCanvas)
//        agoraKit.startPreview()
//    }
//    
//    private func setupRemoteVideoView() {
//        remoteVideo = UIView()
//        remoteVideo.translatesAutoresizingMaskIntoConstraints = false
//        remoteVideo.backgroundColor = .black
//        view.addSubview(remoteVideo)
//        
//        NSLayoutConstraint.activate([
//            remoteVideo.topAnchor.constraint(equalTo: view.topAnchor),
//            remoteVideo.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            remoteVideo.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            remoteVideo.bottomAnchor.constraint(equalTo: view.bottomAnchor)
//        ])
//    }
//    
//    private func setupControlButtons() {
//        // 離開通話按鈕
//        let hangUpButton = UIButton(type: .system)
//        hangUpButton.setImage(UIImage(systemName: "phone.down.fill"), for: .normal)
//        hangUpButton.tintColor = .white
//        hangUpButton.backgroundColor = .red
//        hangUpButton.layer.cornerRadius = 25
//        hangUpButton.translatesAutoresizingMaskIntoConstraints = false
//        hangUpButton.addTarget(self, action: #selector(hangUpButtonTapped), for: .touchUpInside)
//        view.addSubview(hangUpButton)
//        
//        NSLayoutConstraint.activate([
//            hangUpButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            hangUpButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
//            hangUpButton.widthAnchor.constraint(equalToConstant: 50),
//            hangUpButton.heightAnchor.constraint(equalToConstant: 50)
//        ])
//    }
//    
//    @objc private func hangUpButtonTapped() {
//        leaveChannel()
//        dismiss(animated: true, completion: nil)
//    }
//    
////    private func joinChannel() {
////        guard let channelName = self.channelName else {
////            print("頻道名稱未設置")
////            return
////        }
////        
////        print("正在加入頻道: \(channelName)")
////        
////        // 從 Firebase Cloud Functions 獲取 RTC Token
////        fetchAgoraToken(channelName: channelName) { [weak self] token in
////            guard let self = self, let token = token else {
////                DispatchQueue.main.async {
////                    self?.showAlert(message: "無法獲取視頻通話 Token，請稍後再試。")
////                }
////                return
////            }
////            
////            DispatchQueue.main.async {
////                self.token = token
////                self.agoraKit.joinChannel(byToken: token, channelId: channelName, info: nil, uid: 0) { (channel, uid, elapsed) in
////                    print("成功加入頻道：\(channel), uid: \(uid)")
////                }
////            }
////        }
////    }
//    
//    private func joinChannel() {
//        let fixedChannelName = "test" // 使用固定的頻道名稱進行測試
//        
//        print("正在加入頻道: \(fixedChannelName)")
//        
//        // 從 Firebase Cloud Functions 獲取 RTC Token
//        fetchAgoraToken(channelName: fixedChannelName) { [weak self] token in
//            guard let self = self, let token = token else {
//                DispatchQueue.main.async {
//                    self?.showAlert(message: "無法獲取視頻通話 Token，請稍後再試。")
//                }
//                print("Token 獲取失敗或為 nil")
//                return
//            }
//            
//            DispatchQueue.main.async {
//                self.token = "007eJxTYFhfkf2jei77/a2HVjncCTo/dcZincpn2zo2yMScTP5Ve+G+AkNKWlqyWWKKgXlKaoqJoYWZhXGqSZKJgXGSZWqqRVKqoU00d3pDICPDuxuKjIwMEAjiszCUpBaXMDAAAHSuIx4="
//                print("獲取的 Token: \(self.token)") // 打印 Token 以確認其是否有效
//                self.agoraKit.joinChannel(byToken: self.token, channelId: fixedChannelName, info: nil, uid: 0) { (channel, uid, elapsed) in
//                    print("成功加入頻道：\(channel), uid: \(uid)")
//                }
//            }
//        }
//    }
//    
//    private func leaveChannel() {
//        print("正在離開頻道")
//        agoraKit.leaveChannel { (stats) in
//            print("離開頻道，統計數據：\(stats)")
//        }
//        AgoraRtcEngineKit.destroy()
//    }
//    
//    func fetchAgoraToken(channelName: String, completion: @escaping (String?) -> Void) {
//        let parameters: [String: Any] = [
//            "channelName": "BaY4Ogh18ybPvNvTwPbcT98Iijy2_",
//            "expireTimeInSeconds": 3600 // 可以根據需要調整
//        ]
//        
//        guard let url = URL(string: "https://us-central1-edunion-e5403.cloudfunctions.net/generateAgoraToken") else {
//            print("無效的 URL")
//            completion(nil)
//            return
//        }
//        
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//
//        do {
//            let jsonData = try JSONSerialization.data(withJSONObject: parameters, options: [])
//            request.httpBody = jsonData
//        } catch let error {
//            print("序列化 JSON 時出錯: \(error)")
//            completion(nil)
//            return
//        }
//
//        // 發送請求
//        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//            if let error = error {
//                print("錯誤: \(error)")
//                completion(nil)
//                return
//            }
//
//            // 檢查伺服器的回應
//            if let httpResponse = response as? HTTPURLResponse {
//                print("Status Code: \(httpResponse.statusCode)")
//                if httpResponse.statusCode == 200 {
//                    if let data = data {
//                        do {
//                            // 解析伺服器返回的 JSON
//                            if let responseJSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
//                               let token = responseJSON["token"] as? String {
//                                print("生成的 Token: \(token)")
//                                completion(token)
//                            } else {
//                                print("無法解析 token")
//                                completion(nil)
//                            }
//                        } catch let jsonError {
//                            print("解析 JSON 時出錯: \(jsonError)")
//                            completion(nil)
//                        }
//                    }
//                } else {
//                    // 處理非 200 狀態碼的情況
//                    if let data = data,
//                       let errorResponse = String(data: data, encoding: .utf8) {
//                        print("錯誤回應數據: \(errorResponse)")
//                    } else {
//                        print("無法獲取錯誤回應數據")
//                    }
//                    completion(nil)
//                }
//            }
//        }
//
//        task.resume()
//    }
//    
//    private func showAlert(message: String) {
//        let alert = UIAlertController(title: "錯誤", message: message, preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "確定", style: .default, handler: nil))
//        present(alert, animated: true, completion: nil)
//    }
//}
//
//extension VideoCallVC: AgoraRtcEngineDelegate {
//    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
//        print("遠端用戶加入：\(uid)")
//        setupRemoteVideo(uid: uid)
//    }
//    
//    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
//        print("遠端用戶離線：\(uid), 原因：\(reason)")
//        if let remote = remoteVideo {
//            remote.removeFromSuperview()
//            setupRemoteVideoView() // 清除遠端視訊視圖
//        }
//    }
//    
//    private func setupRemoteVideo(uid: UInt) {
//        remoteVideo = UIView()
//        remoteVideo.translatesAutoresizingMaskIntoConstraints = false
//        remoteVideo.backgroundColor = .black
//        view.insertSubview(remoteVideo, belowSubview: localVideo)
//        
//        NSLayoutConstraint.activate([
//            remoteVideo.topAnchor.constraint(equalTo: view.topAnchor),
//            remoteVideo.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            remoteVideo.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            remoteVideo.bottomAnchor.constraint(equalTo: view.bottomAnchor)
//        ])
//        
//        let videoCanvas = AgoraRtcVideoCanvas()
//        videoCanvas.uid = uid
//        videoCanvas.view = remoteVideo
//        videoCanvas.renderMode = .hidden
//        agoraKit.setupRemoteVideo(videoCanvas)
//    }
//}

//class VideoCallVC: UIViewController {
//
//    var agoraView: AgoraVideoViewer?
//    var channelName: String?
//    var token: String?
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        var agSettings = AgoraSettings()
//        agSettings.enabledButtons = [.cameraButton, .micButton, .flipButton]
//        agSettings.buttonPosition = .right
//        AgoraVideoViewer.printLevel = .verbose
//        
//        fetchAgoraToken(channelName: channelName!) { [weak self] token in
//            guard let self = self, let token = token else {
//                DispatchQueue.main.async {
//                    self?.showAlert(message: "無法獲取視頻通話 Token，請稍後再試。")
//                }
//                return
//            }
//            
//            DispatchQueue.main.async {
//                self.token = token
//                self.agoraKit.joinChannel(byToken: token, channelId: channelName, info: nil, uid: 0) { (channel, uid, elapsed) in
//                    print("成功加入頻道：\(channel), uid: \(uid)")
//                }
//            }
//        }
//
//        let agoraView = AgoraVideoViewer(
//            connectionData: AgoraConnectionData(
//                appId: "dffc6ad07ded418683e4b403b9ee8be1",
////                rtcToken: "007eJxTYFhfkf2jei77/a2HVjncCTo/dcZincpn2zo2yMScTP5Ve+G+AkNKWlqyWWKKgXlKaoqJoYWZhXGqSZKJgXGSZWqqRVKqoU00d3pDICPDuxuKjIwMEAjiszCUpBaXMDAAAHSuIx4="
//                rtcToken: token
//            ),
//            style: .floating,
//            agoraSettings: agSettings,
//            delegate: self
//        )
//
//        self.view.backgroundColor = .tertiarySystemBackground
//        agoraView.fills(view: self.view)
//        
//        guard let channelName = channelName, !channelName.isEmpty else {
//            print("頻道名稱未設置")
////            showAlert(message: "頻道名稱未設置")
//            return
//        }
//
//        agoraView.join(channel: channelName, as: .broadcaster)
//
//        self.agoraView = agoraView
//
//        self.showSegmentedView()
//    }
//
//    func fetchAgoraToken(channelName: String, completion: @escaping (String?) -> Void) {
//            let parameters: [String: Any] = [
//                "channelName": channelName,
//                "expireTimeInSeconds": 3600 // 可以根據需要調整
//            ]
//    
//            guard let url = URL(string: "https://us-central1-edunion-e5403.cloudfunctions.net/generateAgoraToken") else {
//                print("無效的 URL")
//                completion(nil)
//                return
//            }
//    
//            var request = URLRequest(url: url)
//            request.httpMethod = "POST"
//            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//    
//            do {
//                let jsonData = try JSONSerialization.data(withJSONObject: parameters, options: [])
//                request.httpBody = jsonData
//            } catch let error {
//                print("序列化 JSON 時出錯: \(error)")
//                completion(nil)
//                return
//            }
//    
//            // 發送請求
//            let task = URLSession.shared.dataTask(with: request) { data, response, error in
//                if let error = error {
//                    print("錯誤: \(error)")
//                    completion(nil)
//                    return
//                }
//    
//                // 檢查伺服器的回應
//                if let httpResponse = response as? HTTPURLResponse {
//                    print("Status Code: \(httpResponse.statusCode)")
//                    if httpResponse.statusCode == 200 {
//                        if let data = data {
//                            do {
//                                // 解析伺服器返回的 JSON
//                                if let responseJSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
//                                   let token = responseJSON["token"] as? String {
//                                    print("生成的 Token: \(token)")
//                                    completion(token)
//                                } else {
//                                    print("無法解析 token")
//                                    completion(nil)
//                                }
//                            } catch let jsonError {
//                                print("解析 JSON 時出錯: \(jsonError)")
//                                completion(nil)
//                            }
//                        }
//                    } else {
//                        // 處理非 200 狀態碼的情況
//                        if let data = data,
//                           let errorResponse = String(data: data, encoding: .utf8) {
//                            print("錯誤回應數據: \(errorResponse)")
//                        } else {
//                            print("無法獲取錯誤回應數據")
//                        }
//                        completion(nil)
//                    }
//                }
//            }
//    
//            task.resume()
//        }
//    
//    func showSegmentedView() {
//        let segControl = UISegmentedControl(items: ["floating", "grid"])
//        segControl.selectedSegmentIndex = 0
//        segControl.addTarget(self, action: #selector(segmentedControlHit), for: .valueChanged)
//        self.view.addSubview(segControl)
//        segControl.translatesAutoresizingMaskIntoConstraints = false
//        [
//            segControl.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 10),
//            segControl.rightAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.rightAnchor, constant: -10)
//        ].forEach { $0.isActive = true }
//        self.view.bringSubviewToFront(segControl)
//    }
//
//    @objc func segmentedControlHit(segc: UISegmentedControl) {
//        print(segc)
//        let segmentedStyle = [
//            AgoraVideoViewer.Style.floating,
//            AgoraVideoViewer.Style.grid
//        ][segc.selectedSegmentIndex]
//        self.agoraView?.style = segmentedStyle
//    }
//}
//
//extension VideoCallVC: AgoraVideoViewerDelegate {
//
//    func extraButtons() -> [UIButton] {
//        let button = UIButton()
//        button.setImage(UIImage(
//            systemName: "bolt.fill",
//            withConfiguration: UIImage.SymbolConfiguration(scale: .large)
//        ), for: .normal)
//        button.backgroundColor = .systemGray
//        button.addTarget(self, action: #selector(self.clickedBolt), for: .touchUpInside)
//        return [button]
//    }
//
//    @objc func clickedBolt(sender: UIButton) {
//        print("zap!")
//        sender.isSelected.toggle()
//        sender.backgroundColor = sender.isSelected ? .systemYellow : .systemGray
//    }
//}

class VideoCallVC: UIViewController {

    var agoraView: AgoraVideoViewer?
    var channelName: String?
    var token: String?
    var onCallEnded: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        print(channelName)
        // 检查频道名称是否已设置
        guard var channelName = self.channelName, !channelName.isEmpty else {
            print("频道名称未设置")
            return
        }
        channelName = "BaY4Ogh18ybPvNvTwPbcT98Iijy2"
        // 获取 Token
        fetchAgoraToken(channelName: channelName) { [weak self] token in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let token = token {
                    self.token = token
                    self.setupAgoraVideoViewer(token: token, channelName: channelName)
                } else {
//                    self.showAlert(message: "无法获取视频通话 Token，请稍后再试。")
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            
            if isBeingDismissed || isMovingFromParent {
                onCallEnded?() // 通知 ChatVC 通話結束
            }
        }

    func setupAgoraVideoViewer(token: String, channelName: String) {
        var agSettings = AgoraSettings()
        agSettings.enabledButtons = [.cameraButton, .micButton, .flipButton]
        agSettings.buttonPosition = .right
        AgoraVideoViewer.printLevel = .verbose

        // 初始化 AgoraVideoViewer，使用获取的 Token
        let agoraView = AgoraVideoViewer(
            connectionData: AgoraConnectionData(
                appId: "dffc6ad07ded418683e4b403b9ee8be1",
                rtcToken: token
            ),
            style: .floating,
            agoraSettings: agSettings,
            delegate: self
        )

        self.view.backgroundColor = .tertiarySystemBackground
        agoraView.fills(view: self.view)
        self.agoraView = agoraView

        // 加入频道
        agoraView.join(channel: channelName, as: .broadcaster)

        self.showSegmentedView()
    }

    func fetchAgoraToken(channelName: String, completion: @escaping (String?) -> Void) {
        let parameters: [String: Any] = [
            "channelName": channelName,
            "expireTimeInSeconds": 3600 // 可根据需要调整
        ]

        guard let url = URL(string: "https://us-central1-edunion-e5403.cloudfunctions.net/generateAgoraToken") else {
            print("无效的 URL")
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: parameters, options: [])
            request.httpBody = jsonData
        } catch let error {
            print("序列化 JSON 时出错: \(error)")
            completion(nil)
            return
        }

        // 发送请求
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("错误: \(error)")
                completion(nil)
                return
            }

            // 检查服务器的响应
            if let httpResponse = response as? HTTPURLResponse {
                print("Status Code: \(httpResponse.statusCode)")
                if httpResponse.statusCode == 200 {
                    if let data = data {
                        do {
                            // 解析服务器返回的 JSON
                            if let responseJSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                               let token = responseJSON["token"] as? String {
                                print("生成的 Token: \(token)")
                                completion(token)
                            } else {
                                print("无法解析 token")
                                completion(nil)
                            }
                        } catch let jsonError {
                            print("解析 JSON 时出错: \(jsonError)")
                            completion(nil)
                        }
                    }
                } else {
                    // 处理非 200 状态码的情况
                    if let data = data,
                       let errorResponse = String(data: data, encoding: .utf8) {
                        print("错误响应数据: \(errorResponse)")
                    } else {
                        print("无法获取错误响应数据")
                    }
                    completion(nil)
                }
            }
        }

        task.resume()
    }

    func showSegmentedView() {
        let segControl = UISegmentedControl(items: ["floating", "grid"])
        segControl.selectedSegmentIndex = 0
        segControl.addTarget(self, action: #selector(segmentedControlHit), for: .valueChanged)
        self.view.addSubview(segControl)
        segControl.translatesAutoresizingMaskIntoConstraints = false
        [
            segControl.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 10),
            segControl.rightAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.rightAnchor, constant: -10)
        ].forEach { $0.isActive = true }
        self.view.bringSubviewToFront(segControl)
    }

    @objc func segmentedControlHit(segc: UISegmentedControl) {
        print(segc)
        let segmentedStyle = [
            AgoraVideoViewer.Style.floating,
            AgoraVideoViewer.Style.grid
        ][segc.selectedSegmentIndex]
        self.agoraView?.style = segmentedStyle
    }
}

extension VideoCallVC: AgoraVideoViewerDelegate {

    func extraButtons() -> [UIButton] {
        // 設置“離開”按鈕
        let leaveButton = UIButton()
        leaveButton.setImage(UIImage(
            systemName: "phone.down.fill",
            withConfiguration: UIImage.SymbolConfiguration(scale: .large)
        ), for: .normal)
        leaveButton.backgroundColor = .systemRed
        leaveButton.addTarget(self, action: #selector(self.leaveChannel), for: .touchUpInside)

        return [leaveButton] // 返回離開按鈕
    }

    @objc func leaveChannel(sender: UIButton) {
        // 調用離開頻道的功能
        print("離開通話")
        self.agoraView?.leaveChannel() // 離開當前頻道
        self.dismiss(animated: true, completion: nil) // 返回上一頁
    }
}
