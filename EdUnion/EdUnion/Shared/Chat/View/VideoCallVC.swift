//
//  VideoCallVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/10/13.
//

import UIKit
import AgoraUIKit

//class VideoCallVC: UIViewController {
//    private var agoraView: AgoraVideoViewer?
//    private let activityIndicator = UIActivityIndicatorView(style: .large)
//
//    var channelName: String?
//    
//    var onCallEnded: (() -> Void)?
//        
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        setupActivityIndicator()
//        
//        guard let channelName = self.channelName, !channelName.isEmpty else {
//            print("無頻道名")
//            return
//        }
//        
//        activityIndicator.startAnimating()
//        
//        fetchAgoraToken(channelName: channelName) { [weak self] token, appId in
//            guard let self = self else { return }
//            
//            DispatchQueue.main.async {
//                if let token = token, let appId = appId {
//                    self.setupAgoraVideoViewer(token: token, appId: appId, channelName: channelName)
//                    self.activityIndicator.stopAnimating()
//                } else {
//                    print("無法獲取視頻通話 Token 或 App ID")
//                    self.activityIndicator.stopAnimating()
//                }
//            }
//        }
//    }
//    
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        
//        if isBeingDismissed || isMovingFromParent {
//            onCallEnded?()
//        }
//    }
//    
//    func setupActivityIndicator() {
//            activityIndicator.color = .gray
//            activityIndicator.translatesAutoresizingMaskIntoConstraints = false
//            view.addSubview(activityIndicator)
//            
//            NSLayoutConstraint.activate([
//                activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//                activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
//            ])
//        }
//    
//    func setupAgoraVideoViewer(token: String, appId: String, channelName: String) {
//        var agSettings = AgoraSettings()
//        
//        agSettings.enabledButtons = [.cameraButton, .micButton, .flipButton]
//        agSettings.buttonPosition = .bottom
//        agSettings.colors.micFlag = .mainOrange
//        agSettings.colors.micButtonNormal = .myGray
//        agSettings.colors.camButtonNormal = .myGray
//        agSettings.colors.camButtonSelected = .mainOrange
//        agSettings.videoRenderMode = .fit
//        agSettings.colors.micButtonSelected = .mainOrange
//        agSettings.colors.buttonTintColor = .white
//        AgoraVideoViewer.printLevel = .verbose
//        
//        let agoraView = AgoraVideoViewer(
//            connectionData: AgoraConnectionData(
//                appId: appId,
//                rtcToken: token
//            ),
//            style: .grid,
//            agoraSettings: agSettings,
//            delegate: self
//        )
//        
//        self.view.backgroundColor = .myBackground
//        agoraView.fills(view: self.view)
//        self.agoraView = agoraView
//        
//        agoraView.join(channel: channelName, as: .broadcaster)
//        
////        self.showSegmentedView()
//        self.agoraView?.style = .grid
//    }
//    
//    func fetchAgoraToken(channelName: String, completion: @escaping (String?, String?) -> Void) {
//        let parameters: [String: Any] = [
//            "channelName": channelName
//        ]
//        
//        guard let url = URL(string: "https://us-central1-edunion-e5403.cloudfunctions.net/generateAgoraToken") else {
//            print("無效的 URL")
//            completion(nil, nil)
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
//            completion(nil, nil)
//            return
//        }
//        
//        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//            if let error = error {
//                print("錯誤: \(error)")
//                completion(nil, nil)
//                return
//            }
//            
//            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data {
//                do {
//                    if let responseJSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
//                       let token = responseJSON["token"] as? String,
//                       let appId = responseJSON["appId"] as? String {
//                        completion(token, appId)
//                    } else {
//                        print("無法解析 token 或 appId")
//                        completion(nil, nil)
//                    }
//                } catch let jsonError {
//                    print("解析 JSON 時出錯: \(jsonError)")
//                    completion(nil, nil)
//                }
//            } else {
//                print("無法獲取 Token，狀態碼不為200")
//                completion(nil, nil)
//            }
//        }
//        
//        task.resume()
//    }
//    
//    func showSegmentedView() {
//        guard let floatingImage = UIImage(systemName: "pin"),
//              let gridImage = UIImage(systemName: "rectangle.grid.1x2") else {
//            print("無法加載 SF Symbols 圖像")
//            return
//        }
//        
//        // 初始化 UISegmentedControl 使用圖像
//        let segControl = UISegmentedControl(items: [floatingImage, gridImage])
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
////            AgoraVideoViewer.Style.pinned,
////            AgoraVideoViewer.Style.custom(customFunction: customLayout),
//            AgoraVideoViewer.Style.grid,
////            AgoraVideoViewer.Style.floating
////            AgoraVideoViewer.Style.pinned,
//            
//        ][segc.selectedSegmentIndex]
//        self.agoraView?.style = segmentedStyle
//    }
//    
//    func customLayout(viewer: AgoraVideoViewer, views: EnumeratedSequence<[UInt: AgoraSingleVideoView]>, localUid: Int) {
//        let viewWidth = viewer.bounds.width
//        let viewHeight = viewer.bounds.height
//
//        // 過濾出本地用戶（自己的視訊流）和遠端用戶的視訊流
//        var localView: AgoraSingleVideoView?
//        var remoteViews: [AgoraSingleVideoView] = []
//
//        for (_, element) in views {
//            if element.key == localUid {
//                localView = element.value // 自己的視訊
//            } else {
//                remoteViews.append(element.value) // 遠端的視訊
//            }
//        }
//
//        // 隱藏本地用戶的視窗
//        if let localView = localView {
//            localView.isHidden = true // 隱藏本地的畫面
//        }
//
//        // 確保顯示的遠端視窗不超過兩個
//        let displayedRemoteViews = remoteViews.prefix(2)
//
//        for (index, remoteView) in displayedRemoteViews.enumerated() {
//            remoteView.translatesAutoresizingMaskIntoConstraints = false
//            viewer.addSubview(remoteView)
//
//            NSLayoutConstraint.activate([
//                remoteView.leadingAnchor.constraint(equalTo: viewer.leadingAnchor),
//                remoteView.trailingAnchor.constraint(equalTo: viewer.trailingAnchor),
//                remoteView.heightAnchor.constraint(equalTo: viewer.heightAnchor, multiplier: 0.5),
//                remoteView.topAnchor.constraint(equalTo: viewer.topAnchor, constant: CGFloat(index) * (viewHeight / 2))
//            ])
//        }
//
//        // 隱藏多餘的遠端視窗
//        if remoteViews.count > 2 {
//            for remoteView in remoteViews.dropFirst(2) {
//                remoteView.isHidden = true
//            }
//        }
//
//        // 強制佈局更新
//        viewer.layoutIfNeeded()
//    }
//}
//
//extension VideoCallVC: AgoraVideoViewerDelegate {
//    
//    func extraButtons() -> [UIButton] {
//        let leaveButton = UIButton()
//        leaveButton.setImage(UIImage(
//            systemName: "xmark",
//            withConfiguration: UIImage.SymbolConfiguration(scale: .large)
//        ), for: .normal)
//        leaveButton.tintColor = .white
//        leaveButton.backgroundColor = .systemRed
//        leaveButton.addTarget(self, action: #selector(self.leaveChannel), for: .touchUpInside)
//        
//        return [leaveButton]
//    }
//    
//    @objc func leaveChannel(sender: UIButton) {
//        print("離開通話")
//        self.agoraView?.leaveChannel()
//        self.dismiss(animated: true, completion: nil)
//    }
//}

class VideoCallVC: UIViewController {
    private var agoraView: AgoraVideoViewer?
    private let activityIndicator = UIActivityIndicatorView(style: .large)

    var channelName: String?
    var onCallEnded: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupActivityIndicator()
        
        guard let channelName = self.channelName, !channelName.isEmpty else {
            print("無頻道名")
            return
        }
        
        activityIndicator.startAnimating()
        
        fetchAgoraToken(channelName: channelName) { [weak self] token, appId in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let token = token, let appId = appId {
                    self.setupAgoraVideoViewer(token: token, appId: appId, channelName: channelName)
                    self.activityIndicator.stopAnimating()
                } else {
                    print("無法獲取視頻通話 Token 或 App ID")
                    self.activityIndicator.stopAnimating()
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if isBeingDismissed || isMovingFromParent {
            onCallEnded?()
        }
    }
    
    func setupActivityIndicator() {
        activityIndicator.color = .gray
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    func setupAgoraVideoViewer(token: String, appId: String, channelName: String) {
        var agSettings = AgoraSettings()
        
        agSettings.enabledButtons = [.cameraButton, .micButton, .flipButton]
        agSettings.buttonPosition = .bottom
        agSettings.colors.micFlag = .mainOrange
        agSettings.colors.micButtonNormal = .myGray
        agSettings.colors.camButtonNormal = .myGray
        agSettings.colors.camButtonSelected = .mainOrange
        agSettings.videoRenderMode = .hidden 
        agSettings.colors.micButtonSelected = .mainOrange
        agSettings.colors.buttonTintColor = .white
        
        AgoraVideoViewer.printLevel = .verbose
        
        // 初始化 AgoraVideoViewer，使用 grid 樣式
        let agoraView = AgoraVideoViewer(
            connectionData: AgoraConnectionData(
                appId: appId,
                rtcToken: token
            ),
            style: .grid,
            agoraSettings: agSettings,
            delegate: self
        )
        
//        let placeholderView = UIImageView(image: UIImage(systemName: "pin"))
//        placeholderView.tintColor = .lightGray
//        placeholderView.contentMode = .scaleAspectFit
//        agoraView.placeholder = placeholderView
        
        self.view.backgroundColor = .myBackground
        agoraView.fills(view: self.view)
        self.agoraView = agoraView
        
        agoraView.join(channel: channelName, as: .broadcaster)
    }
    
    func fetchAgoraToken(channelName: String, completion: @escaping (String?, String?) -> Void) {
        let parameters: [String: Any] = [
            "channelName": channelName
        ]
        
        guard let url = URL(string: "https://us-central1-edunion-e5403.cloudfunctions.net/generateAgoraToken") else {
            print("無效的 URL")
            completion(nil, nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: parameters, options: [])
            request.httpBody = jsonData
        } catch let error {
            print("序列化 JSON 時出錯: \(error)")
            completion(nil, nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("錯誤: \(error)")
                completion(nil, nil)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data {
                do {
                    if let responseJSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let token = responseJSON["token"] as? String,
                       let appId = responseJSON["appId"] as? String {
                        completion(token, appId)
                    } else {
                        print("無法解析 token 或 appId")
                        completion(nil, nil)
                    }
                } catch let jsonError {
                    print("解析 JSON 時出錯: \(jsonError)")
                    completion(nil, nil)
                }
            } else {
                print("無法獲取 Token，狀態碼不為200")
                completion(nil, nil)
            }
        }
        
        task.resume()
    }
    
    func showSegmentedView() {
        guard let floatingImage = UIImage(systemName: "pin"),
              let gridImage = UIImage(systemName: "rectangle.grid.1x2") else {
            print("無法加載 SF Symbols 圖像")
            return
        }
        
        // 初始化 UISegmentedControl 使用圖像
        let segControl = UISegmentedControl(items: [floatingImage, gridImage])
        segControl.selectedSegmentIndex = 0
        segControl.addTarget(self, action: #selector(segmentedControlHit), for: .valueChanged)
        self.view.addSubview(segControl)
        segControl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            segControl.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 10),
            segControl.rightAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.rightAnchor, constant: -10),
            segControl.widthAnchor.constraint(equalToConstant: 150),
            segControl.heightAnchor.constraint(equalToConstant: 40)
        ])
        self.view.bringSubviewToFront(segControl)
    }
    
    @objc func segmentedControlHit(segc: UISegmentedControl) {
        print(segc)
        let segmentedStyle = [
            AgoraVideoViewer.Style.grid,
            AgoraVideoViewer.Style.custom(customFunction: customLayout)
        ][segc.selectedSegmentIndex]
        self.agoraView?.style = segmentedStyle
    }
    
    // 自訂布局函數，接受三個參數
    func customLayout(viewer: AgoraVideoViewer, views: EnumeratedSequence<[UInt: AgoraSingleVideoView]>, localUid: Int) {
        let viewWidth = viewer.bounds.width
        let viewHeight = viewer.bounds.height

        // 打印尺寸以調試
        print("Viewer Width: \(viewWidth), Viewer Height: \(viewHeight)")

        // 過濾出本地用戶（自己的視訊流）和遠端用戶的視訊流
        var localView: AgoraSingleVideoView?
        var remoteViews: [AgoraSingleVideoView] = []

        for (_, element) in views {
            print("UID: \(element.key), View: \(element.value)")
            if element.key == UInt(localUid) {
                localView = element.value // 自己的視訊
            } else {
                remoteViews.append(element.value) // 遠端的視訊
            }
        }

        // 隱藏本地用戶的視窗
        if let localView = localView {
            localView.isHidden = true // 隱藏本地的畫面
        }

        // 確保顯示的遠端視窗不超過兩個，並上下排列
        let displayedRemoteViews = remoteViews.prefix(2)

        for (index, remoteView) in displayedRemoteViews.enumerated() {
            let halfHeight = viewHeight / 2
            let frame = CGRect(x: 0, y: CGFloat(index) * halfHeight, width: viewWidth, height: halfHeight)
            remoteView.frame = frame
            remoteView.backgroundColor = (index % 2 == 0) ? .red : .blue
            remoteView.isHidden = false
            print("Remote View \(index) Frame: \(remoteView.frame)")
        }

        if remoteViews.count > 2 {
            for remoteView in remoteViews.dropFirst(2) {
                remoteView.isHidden = true
            }
        }

        viewer.layoutIfNeeded()
    }
}

extension VideoCallVC: AgoraVideoViewerDelegate {
    
    func extraButtons() -> [UIButton] {
        let leaveButton = UIButton()
        leaveButton.setImage(UIImage(
            systemName: "xmark",
            withConfiguration: UIImage.SymbolConfiguration(scale: .large)
        ), for: .normal)
        leaveButton.tintColor = .white
        leaveButton.backgroundColor = .mainOrange
        leaveButton.addTarget(self, action: #selector(self.leaveChannel), for: .touchUpInside)
        
        return [leaveButton]
    }
    
    @objc func leaveChannel(sender: UIButton) {
        print("離開通話")
        self.agoraView?.leaveChannel()
        self.dismiss(animated: true, completion: nil)
    }
}
