//
//  VideoCallVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/10/13.
//

import UIKit
import AgoraUIKit

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
        
        self.view.backgroundColor = .myBackground
        agoraView.fills(view: self.view)
        self.agoraView = agoraView
        
        agoraView.join(channel: channelName, as: .broadcaster)
        
//        self.showSegmentedView()
        self.agoraView?.style = .floating
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
            AgoraVideoViewer.Style.floating
//            AgoraVideoViewer.Style.grid
//            AgoraVideoViewer.Style.pinned
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
        
        return [leaveButton]
    }
    
    @objc func leaveChannel(sender: UIButton) {
        print("離開通話")
        self.agoraView?.leaveChannel()
        self.dismiss(animated: true, completion: nil)
    }
}
