//
//  ChatListVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/17.
//

import UIKit

class ChatListVC: UIViewController {

    private let tableView = UITableView()
    private var chatRooms: [ChatRoom] = []
    private let participantID: String = teacherID  // 你要過濾的參與者 ID
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        fetchChatRooms()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tabBarController?.tabBar.isHidden = false
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "chatRoomCell")
        tableView.frame = self.view.bounds
        self.view.addSubview(tableView)
    }
    
    private func fetchChatRooms() {
        FirebaseService.shared.fetchChatRooms(for: participantID) { [weak self] (chatRooms, error) in
            if let error = error {
                print("Error fetching chat rooms: \(error.localizedDescription)")
                return
            }
            
            guard let chatRooms = chatRooms else {
                print("No chat rooms returned from Firestore")
                return
            }
            
            if chatRooms.isEmpty {
                print("No chat rooms matched the query.")
            }
            
            self?.chatRooms = chatRooms
            self?.tableView.reloadData()
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension ChatListVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatRooms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "chatRoomCell", for: indexPath)
        let chatRoom = chatRooms[indexPath.row]
        
        let lastMessage = chatRoom.lastMessage ?? "No messages yet"
        let lastMessageTime = chatRoom.lastMessageTimestamp?.formattedDate() ?? ""
        cell.textLabel?.text = chatRoom.participants[1]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // 點擊聊天室進入對應的聊天頁面
        let selectedChatRoom = chatRooms[indexPath.row]
        let chatViewController = ChatVC()
        navigationController?.pushViewController(chatViewController, animated: true)
    }
}

// 日期格式化工具
extension Date {
    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}
