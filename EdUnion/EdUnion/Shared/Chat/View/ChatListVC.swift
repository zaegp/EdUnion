//
//  ChatListVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/17.
//

import UIKit

class ChatListVC: UIViewController {
    
    private let tableView = UITableView()
    private let searchBar = UISearchBar()
    private var chatRooms: [ChatRoom] = []
    private var filteredChatRooms: [ChatRoom] = []
    private let participantID: String = teacherID
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        fetchChatRooms()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = false
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
    
    private func fetchChatRooms() {
        UserFirebaseService.shared.fetchChatRooms(for: participantID) { [weak self] result in
            switch result {
            case .success(let chatRooms):
                guard !chatRooms.isEmpty else {
                    print("No chat rooms returned from Firestore")
                    return
                }
                
                self?.chatRooms = chatRooms.sorted {
                    ($0.lastMessageTimestamp ?? Date()) > ($1.lastMessageTimestamp ?? Date())
                }
                self?.filteredChatRooms = self?.chatRooms ?? []
                self?.tableView.reloadData()

            case .failure(let error):
                print("Error fetching chat rooms: \(error.localizedDescription)")
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
        
        // 配置 cell 顯示對方名字、最後一則消息和時間
        let participantName = chatRoom.participants.filter { $0 != participantID }.first ?? "未知用戶"
        let lastMessage = chatRoom.lastMessage ?? "沒有消息"
        let lastMessageTime = chatRoom.lastMessageTimestamp?.formattedChatDate() ?? ""
        
        cell.configure(name: participantName, lastMessage: lastMessage, time: lastMessageTime)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedChatRoom = filteredChatRooms[indexPath.row]
        let chatViewController = ChatVC()
        navigationController?.pushViewController(chatViewController, animated: true)
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


