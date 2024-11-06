//
//  VideoCallVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/10/13.
//

import UIKit
import AgoraUIKit

struct AgoraTokenResponse: Codable {
    let token: String
    let appId: String
}

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case encodingError(Error)
    case networkError(Error)
    case noData
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無效的 URL"
        case .encodingError(let error):
            return "編碼錯誤: \(error.localizedDescription)"
        case .networkError(let error):
            return "網路錯誤: \(error.localizedDescription)"
        case .noData:
            return "沒有數據返回"
        case .decodingError(let error):
            return "解碼錯誤: \(error.localizedDescription)"
        }
    }
}

class VideoCallVC: UIViewController {
    private var agoraView: AgoraVideoViewer?
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    
    var channelName: String?
    
    var onCallEnded: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        joinAgoraChannel()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if isBeingDismissed || isMovingFromParent {
            onCallEnded?()
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .myBackground
        setupActivityIndicator()
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
    
    private func joinAgoraChannel() {
        guard let channelName = channelName?.trimmingCharacters(in: .whitespacesAndNewlines), !channelName.isEmpty else {
            showNetworkError()
            return
        }
        
        activityIndicator.startAnimating()
        fetchAgoraToken(for: channelName) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.activityIndicator.stopAnimating()
                switch result {
                case .success(let tokenResponse):
                    self.setupAgoraVideoViewer(token: tokenResponse.token, appId: tokenResponse.appId, channelName: channelName)
                case .failure(let error):
                    self.showNetworkError()
                }
            }
        }
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
        
        let agoraView = AgoraVideoViewer(
            connectionData: AgoraConnectionData(
                appId: appId,
                rtcToken: token
            ),
            style: .grid,
            agoraSettings: agSettings,
            delegate: self
        )
        
        self.view.backgroundColor = .myBackground
        agoraView.fills(view: self.view)
        self.agoraView = agoraView
        
        agoraView.join(channel: channelName, as: .broadcaster)
    }
    
    private func fetchAgoraToken(for channelName: String, completion: @escaping (Result<AgoraTokenResponse, Error>) -> Void) {
        let urlString = "https://us-central1-edunion-e5403.cloudfunctions.net/generateAgoraToken"
        guard let url = URL(string: urlString) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        let parameters = ["channelName": channelName]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(parameters)
        } catch {
            completion(.failure(NetworkError.encodingError(error)))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(NetworkError.networkError(error)))
                return
            }
            
            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }
            
            do {
                let tokenResponse = try JSONDecoder().decode(AgoraTokenResponse.self, from: data)
                completion(.success(tokenResponse))
            } catch {
                completion(.failure(NetworkError.decodingError(error)))
            }
        }
        task.resume()
    }
    
    private func showNetworkError() {
        let alert = UIAlertController(title: "錯誤", message: "請檢查網路連線", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "確定", style: .default, handler: { [weak self] _ in
            self?.dismiss(animated: true, completion: nil)
        }))
        present(alert, animated: true, completion: nil)
    }
    
    @objc func leaveChannel(sender: UIButton) {
        print("離開通話")
        self.agoraView?.leaveChannel()
        self.dismiss(animated: true, completion: nil)
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
}
