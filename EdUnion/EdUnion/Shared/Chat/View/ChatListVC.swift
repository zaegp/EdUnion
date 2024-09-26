//
//  ChatListVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/17.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class ChatListVC: UIViewController {
    
    private let tableView = UITableView()
    private let searchBar = UISearchBar()
    private let cancelButton = UIButton(type: .system)
    private var searchBarWidthConstraint: NSLayoutConstraint?
    
    private var chatRooms: [ChatRoom] = []
    private var filteredChatRooms: [ChatRoom] = []
    private var participantID: String?
    private var participantNames: [String: String] = [:]
    private var chatRoomListener: ListenerRegistration?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let currentUserID = Auth.auth().currentUser?.uid {
            participantID = currentUserID
        } else {
            print("Error: Unable to get current user ID.")
        }
        
        setupUI()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        observeChatRooms()
        
        tabBarController?.tabBar.isHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        chatRoomListener?.remove()
    }
    
    private func setupUI() {
        searchBar.delegate = self
        searchBar.placeholder = "搜尋"
        searchBar.sizeToFit()
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        
        cancelButton.setTitle("取消", for: .normal)
        cancelButton.tintColor = .backButton
        cancelButton.isHidden = true
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        
        let searchContainer = UIView()
        searchContainer.translatesAutoresizingMaskIntoConstraints = false
        searchContainer.addSubview(searchBar)
        searchContainer.addSubview(cancelButton)
        
        navigationItem.titleView = searchContainer
        
        searchBarWidthConstraint = searchBar.widthAnchor.constraint(equalTo: searchContainer.widthAnchor)
        
        NSLayoutConstraint.activate([
            searchContainer.widthAnchor.constraint(equalToConstant: view.frame.width),
            searchContainer.heightAnchor.constraint(equalToConstant: 44),
            
            searchBar.leadingAnchor.constraint(equalTo: searchContainer.leadingAnchor),
            searchBar.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),
            searchBarWidthConstraint!,
            
            cancelButton.leadingAnchor.constraint(equalTo: searchBar.trailingAnchor),
            cancelButton.trailingAnchor.constraint(equalTo: searchContainer.trailingAnchor),
            cancelButton.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor)
        ])
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ChatRoomCell.self, forCellReuseIdentifier: "chatRoomCell")
        tableView.frame = self.view.bounds
        tableView.tableFooterView = UIView()
        self.view.addSubview(tableView)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        cancelButton.isHidden = false
        
        searchBarWidthConstraint?.isActive = false
        searchBarWidthConstraint = searchBar.widthAnchor.constraint(equalTo: navigationItem.titleView!.widthAnchor, multiplier: 0.85)
        searchBarWidthConstraint?.isActive = true
        
        UIView.animate(withDuration: 0.3) {
            self.navigationItem.titleView?.layoutIfNeeded()
        }
    }
    
    @objc private func cancelButtonTapped() {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        
        searchBarWidthConstraint?.isActive = false
        searchBarWidthConstraint = searchBar.widthAnchor.constraint(equalTo: navigationItem.titleView!.widthAnchor)
        searchBarWidthConstraint?.isActive = true
        
        UIView.animate(withDuration: 0.3) {
            self.cancelButton.isHidden = true
            self.navigationItem.titleView?.layoutIfNeeded()
        }
        
        tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    private func observeChatRooms() {
        UserFirebaseService.shared.fetchChatRooms(for: participantID ?? "") { [weak self] (chatRooms, error) in
            if let error = error {
                print("Error fetching chat rooms: \(error.localizedDescription)")
                return
            }
            
            guard let chatRooms = chatRooms else {
                print("No chat rooms found.")
                return
            }
            
            self?.chatRooms = chatRooms
            
            for chatRoom in chatRooms {
                let participantId = chatRoom.participants.filter { $0 != self?.participantID }.first ?? "未知用戶"
                
                if let userRole = UserDefaults.standard.string(forKey: "userRole") {
                    if userRole == "student" {
                        UserFirebaseService.shared.fetchName(from: "students", by: participantId) { [weak self] result in
                            switch result {
                            case .success(let studentName):
                                self?.participantNames[chatRoom.id] = studentName
                            case .failure:
                                self?.participantNames[chatRoom.id] = "Unknown Student"
                            }
                            DispatchQueue.main.async {
                                self?.tableView.reloadData()
                            }
                        }
                    } else if userRole == "teacher" {
                        UserFirebaseService.shared.fetchName(from: "teachers", by: participantId) { [weak self] result in
                            switch result {
                            case .success(let teacherName):
                                self?.participantNames[chatRoom.id] = teacherName
                            case .failure:
                                self?.participantNames[chatRoom.id] = "Unknown Teacher"
                            }
                            DispatchQueue.main.async {
                                self?.tableView.reloadData()
                            }
                        }
                    } else {
                        print("Error: Unknown user role.")
                    }
                } else {
                    print("Error: Unable to get user role from UserDefaults.")
                }
            }
            
            self?.filteredChatRooms = chatRooms
            
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
    }
}

extension ChatListVC: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredChatRooms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "chatRoomCell", for: indexPath) as! ChatRoomCell
        let chatRoom = filteredChatRooms[indexPath.row]
        
        let participantId = chatRoom.participants.filter { $0 != participantID }.first ?? "未知用戶"
        print("111111")
        print(participantId)
        
        let lastMessage = chatRoom.lastMessage ?? "沒有消息"
        let lastMessageTime = chatRoom.lastMessageTimestamp?.dateValue().formattedChatDate() ?? ""
        
        if let intID = Int(participantId) {
            if intID % 2 == 0 {
                // 偶數 -> 查詢學生
                UserFirebaseService.shared.fetchName(from: "students", by: participantId) { result in
                    switch result {
                    case .success(let studentName):
                        DispatchQueue.main.async {
                            let name = studentName ?? "Unknown Student"
                            cell.configure(name: name, lastMessage: lastMessage, time: lastMessageTime)
                        }
                    case .failure:
                        DispatchQueue.main.async {
                            cell.configure(name: "Unknown Student", lastMessage: lastMessage, time: lastMessageTime)
                        }
                    }
                }
            } else {
                // 奇數 -> 查詢老師
                UserFirebaseService.shared.fetchName(from: "teachers", by: participantId) { result in
                    switch result {
                    case .success(let teacherName):
                        DispatchQueue.main.async {
                            let name = teacherName ?? "Unknown Teacher"
                            // 更新 cell 的名稱
                            cell.configure(name: name, lastMessage: lastMessage, time: lastMessageTime)
                        }
                    case .failure:
                        DispatchQueue.main.async {
                            // 更新 cell 的名稱
                            cell.configure(name: "Unknown Teacher", lastMessage: lastMessage, time: lastMessageTime)
                        }
                    }
                }
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedChatRoom = filteredChatRooms[indexPath.row]
        let chatVC = ChatVC()
        chatVC.teacherID = selectedChatRoom.participants[0]
        chatVC.studentID = selectedChatRoom.participants[1]
        navigationController?.pushViewController(chatVC, animated: true)
    }
}

class ChatRoomCell: UITableViewCell {
    
    private let nameLabel = UILabel()
    private let lastMessageLabel = UILabel()
    private let timeLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        nameLabel.font = UIFont.boldSystemFont(ofSize: 16)
        lastMessageLabel.font = UIFont.systemFont(ofSize: 14)
        lastMessageLabel.textColor = .gray
        timeLabel.font = UIFont.systemFont(ofSize: 12)
        timeLabel.textColor = .lightGray
        
        contentView.addSubview(nameLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(lastMessageLabel)
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        lastMessageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            
            timeLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            timeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            lastMessageLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            lastMessageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16)
        ])
    }
    
    func configure(name: String, lastMessage: String, time: String) {
        nameLabel.text = name
        lastMessageLabel.text = lastMessage
        timeLabel.text = time
    }
}

extension ChatListVC: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredChatRooms = chatRooms
        } else {
            filteredChatRooms = chatRooms.filter { chatRoom in
                let participantName = participantNames[chatRoom.id] ?? ""
                return participantName.lowercased().contains(searchText.lowercased())
            }
        }
        tableView.reloadData()
    }
}

