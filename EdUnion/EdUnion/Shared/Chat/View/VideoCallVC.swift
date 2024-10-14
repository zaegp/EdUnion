//
//  VideoCallVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/10/13.
//

import UIKit
import AgoraUIKit

class VideoCallVC: UIViewController {
    var agoraView: AgoraVideoViewer?
    var channelName: String?
    var token: String?
    var appId: String?
    var onCallEnded: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let channelName = self.channelName, !channelName.isEmpty else {
            print("频道名称未设置")
            return
        }
        
        fetchAgoraToken(channelName: channelName) { [weak self] token, appId in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let token = token, let appId = appId {
                    self.token = token
                    self.appId = appId
                    self.setupAgoraVideoViewer(token: token, appId: appId, channelName: channelName)
                } else {
                    print("无法获取视频通话 Token 或 App ID")
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
    
    func setupAgoraVideoViewer(token: String, appId: String, channelName: String) {
        var agSettings = AgoraSettings()
        
        agSettings.enabledButtons = [.cameraButton, .micButton, .flipButton]
        agSettings.buttonPosition = .right
        AgoraVideoViewer.printLevel = .verbose
        
        let agoraView = AgoraVideoViewer(
            connectionData: AgoraConnectionData(
                appId: appId,
                rtcToken: token
            ),
            style: .floating,
            agoraSettings: agSettings,
            delegate: self
        )
        
        self.view.backgroundColor = .tertiarySystemBackground
        agoraView.fills(view: self.view)
        self.agoraView = agoraView
        
        agoraView.join(channel: channelName, as: .broadcaster)
        
        self.showSegmentedView()
    }
    
    func fetchAgoraToken(channelName: String, completion: @escaping (String?, String?) -> Void) {
        let parameters: [String: Any] = [
            "channelName": channelName,
        ]
        
        guard let url = URL(string: "https://us-central1-edunion-e5403.cloudfunctions.net/generateAgoraToken") else {
            print("无效的 URL")
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
            print("序列化 JSON 时出错: \(error)")
            completion(nil, nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("错误: \(error)")
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
                        print("无法解析 token 或 appId")
                        completion(nil, nil)
                    }
                } catch let jsonError {
                    print("解析 JSON 时出错: \(jsonError)")
                    completion(nil, nil)
                }
            } else {
                print("无法获取 Token，状态码不为200")
                completion(nil, nil)
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
        let leaveButton = UIButton()
        leaveButton.setImage(UIImage(
            systemName: "phone.down.fill",
            withConfiguration: UIImage.SymbolConfiguration(scale: .large)
        ), for: .normal)
        leaveButton.tintColor = .white
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
