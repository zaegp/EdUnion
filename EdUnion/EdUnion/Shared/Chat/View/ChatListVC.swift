//
//  ChatListVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/17.
//

import UIKit
import FirebaseFirestore

class ChatListVC: UIViewController {
    
    private let tableView = UITableView()
    private let searchBar = UISearchBar()
    private var chatRooms: [ChatRoom] = []
    private var filteredChatRooms: [ChatRoom] = []
    private let participantID: String = studentID
    private var chatRoomListener: ListenerRegistration?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        observeChatRooms()  // 監聽聊天室變化
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        chatRoomListener?.remove()
    }
    
    private func setupUI() {
        // 設置 Search Bar
        searchBar.delegate = self
        searchBar.placeholder = "搜尋"
        searchBar.sizeToFit()
        navigationItem.titleView = searchBar
        
        // 設置 TableView
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ChatRoomCell.self, forCellReuseIdentifier: "chatRoomCell")
        tableView.frame = self.view.bounds
        tableView.tableFooterView = UIView() // 移除空行的分隔線
        self.view.addSubview(tableView)
    }
    
    // 監聽聊天室變化
    private func observeChatRooms() {
        chatRoomListener = UserFirebaseService.shared.db.collection("chats")
            .whereField("participants", arrayContains: participantID)
            .addSnapshotListener { [weak self] (snapshot, error) in
                if let error = error {
                    print("Error fetching chat rooms: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No chat rooms found.")
                    return
                }
                print("Fetched \(documents.count) chat rooms")
                self?.chatRooms = documents.compactMap { doc -> ChatRoom? in
                    do {
                        let chatRoom = try doc.data(as: ChatRoom.self)
                        print("Successfully parsed chat room: \(chatRoom)")  // 確認解析成功
                        return chatRoom
                    } catch {
                        print("Error parsing chat room: \(error)")  // 捕獲解析錯誤
                        return nil
                    }
                }
                
                self?.filteredChatRooms = self?.chatRooms ?? []
                
                DispatchQueue.main.async {
                    print("Filtered chat rooms: \(self!.filteredChatRooms)")
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
                            // 更新 cell 的名稱
                            cell.configure(name: name, lastMessage: lastMessage, time: lastMessageTime)
                        }
                    case .failure:
                        DispatchQueue.main.async {
                            // 更新 cell 的名稱
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
                let participantName = chatRoom.participants.filter { $0 != participantID }.first ?? ""
                return participantName.lowercased().contains(searchText.lowercased())
            }
        }
        tableView.reloadData()
    }
}

