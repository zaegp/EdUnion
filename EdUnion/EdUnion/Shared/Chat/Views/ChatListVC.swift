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
    
    var theTeacher: Teacher?
    var theStudent: Student?
    private let userID = UserSession.shared.unwrappedUserID
    private var isLoading: Bool = true
    
    private var chatRooms: [ChatRoom] = []
    private var filteredChatRooms: [ChatRoom] = []
    private var participants: [String: UserProtocol] = [:]
    private let tableView = UITableView()
    private let searchBarView = SearchBarView()
    private var isDataReloadNeeded = true
    private var unreadCounts: [String: Int] = [:]
    
    private let noChatRoomsView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let imageView = UIImageView(image: UIImage(systemName: "bubble.left.and.bubble.right.fill"))
        imageView.tintColor = .myBlack
        
        let label = UILabel()
        label.text = "暫無聊天訊息，開始新的聊天吧！"
        label.textColor = .label
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(imageView)
        view.addSubview(label)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            
            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 10),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        return view
    }()
    
    private let noSearchResultsView: UIView = {
        let view = UIView()
        
        let imageView = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        imageView.tintColor = .label
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = "找不到相關聊天記錄。"
        label.textColor = .label
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(imageView)
        view.addSubview(label)
        
        view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            
            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 10),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.allowsSelection = !isLoading
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.barTintColor = .myBackground
        navigationController?.navigationBar.shadowImage = UIImage()
        
        tabBarController?.tabBar.isHidden = true
        if let tabBarController = self.tabBarController as? TabBarController {
            tabBarController.setCustomTabBarHidden(false, animated: true)
        }
        
        if isDataReloadNeeded {
                observeChatRooms()
            }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        isDataReloadNeeded = true
    }
    
    private func setupUI() {
        view.backgroundColor = .myBackground
        
        searchBarView.delegate = self
        navigationItem.titleView = searchBarView
        searchBarView.layer.borderWidth = 0
        self.view.addSubview(tableView)
        view.addSubview(noChatRoomsView)
        view.addSubview(noSearchResultsView)
        
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ChatListCell.self, forCellReuseIdentifier: "ChatListCell")
        tableView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height - 80)
        tableView.backgroundColor = .myBackground
        tableView.tableFooterView = UIView()
        
        searchBarView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            searchBarView.widthAnchor.constraint(equalToConstant: view.frame.width),
            searchBarView.heightAnchor.constraint(equalToConstant: 44),
            
            noChatRoomsView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noChatRoomsView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            noSearchResultsView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noSearchResultsView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    private func observeChatRooms() {
        isLoading = true
        noChatRoomsView.isHidden = true
        noSearchResultsView.isHidden = true
        tableView.reloadData()
        
        guard let userRole = UserDefaults.standard.string(forKey: "userRole") else {
            print("Error: Unable to get user role from UserDefaults.")
            isLoading = false
            updateUI(for: [])
            return
        }
        
        let isTeacher = (userRole == "teacher")
        
        UserFirebaseService.shared.fetchChatRooms(
            for: userID,
            isTeacher: isTeacher
        ) { [weak self] (chatRooms, error) in
            guard let self = self else { return }
            
            self.isLoading = false
            
            if let error = error {
                print("Error fetching chat rooms: \(error.localizedDescription)")
                self.chatRooms = []
                self.filteredChatRooms = []
                self.updateUI(for: [])
                return
            }
            
            guard let chatRooms = chatRooms, !chatRooms.isEmpty else {
                print("No chat rooms found.")
                self.chatRooms = []
                self.filteredChatRooms = []
                self.updateUI(for: [])
                return
            }
            
            self.chatRooms = chatRooms
            self.filteredChatRooms = chatRooms
            
            self.fetchParticipants(for: chatRooms, isTeacher: isTeacher) {
                self.filteredChatRooms = self.chatRooms
                self.updateUI(for: self.filteredChatRooms)
            }
        }
    }
    
    private func fetchParticipants(for chatRooms: [ChatRoom], isTeacher: Bool, completion: @escaping () -> Void) {
        let dispatchGroup = DispatchGroup()
        
        for chatRoom in chatRooms {
            dispatchGroup.enter()
            let participantId = chatRoom.participants.first { $0 != self.userID } ?? "未知用戶"
            
            let fetchUserCompletion: (Result<UserProtocol, Error>) -> Void = { [weak self] result in
                guard let self = self else { return }
                self.handleFetchResult(result, for: chatRoom.id)
                
                self.fetchUnreadCount(for: chatRoom.id) { unreadCount in
                    self.unreadCounts[chatRoom.id] = unreadCount
                    dispatchGroup.leave()
                }
            }
            
            if isTeacher {
                UserFirebaseService.shared.fetchUser(
                    from: Constants.studentsCollection,
                    by: participantId,
                    as: Student.self
                ) { [weak self] result in
                    guard let self = self else { return }
                    
                    let convertedResult: Result<any UserProtocol, Error> = result.map { $0 as any UserProtocol }
                    self.handleFetchResult(convertedResult, for: chatRoom.id)
                    
                    self.fetchUnreadCount(for: chatRoom.id) { unreadCount in
                        self.unreadCounts[chatRoom.id] = unreadCount
                        print("Unread count set for chatRoomID \(chatRoom.id): \(unreadCount)")
                        dispatchGroup.leave()
                    }
                }
            } else {
                UserFirebaseService.shared.fetchUser(
                    from: Constants.teachersCollection,
                    by: participantId,
                    as: Teacher.self
                ) { [weak self] result in
                    guard let self = self else { return }
                    
                    let convertedResult: Result<any UserProtocol, Error> = result.map { $0 as any UserProtocol }
                    self.handleFetchResult(convertedResult, for: chatRoom.id)
                    
                    self.fetchUnreadCount(for: chatRoom.id) { unreadCount in
                        self.unreadCounts[chatRoom.id] = unreadCount
                        print("Unread count set for chatRoomID \(chatRoom.id): \(unreadCount)")
                        dispatchGroup.leave()
                    }
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.chatRooms = self.chatRooms.filter { self.participants[$0.id] != nil }
            self.filteredChatRooms = self.chatRooms
            self.tableView.reloadData()
            completion()
        }
    }
    
    private func handleFetchResult(_ result: Result<any UserProtocol, Error>, for chatRoomID: String) {
        switch result {
        case .success(let user):
            if let student = user as? Student {
                participants[chatRoomID] = student
            } else if let teacher = user as? Teacher {
                participants[chatRoomID] = teacher
            } else {
                print("Error: User type is unknown or mismatched.")
            }
        case .failure(let error):
            print("Error fetching participant for chat room \(chatRoomID): \(error.localizedDescription)")
            participants[chatRoomID] = nil
        }
    }
    
    private func updateUI(for chatRooms: [ChatRoom]) {
        noChatRoomsView.isHidden = !chatRooms.isEmpty
        tableView.reloadData()
    }
    
    private func fetchUnreadCount(for chatRoomID: String, completion: @escaping (Int) -> Void) {
        let messagesRef = Firestore.firestore()
            .collection("chats")
            .document(chatRoomID)
            .collection("messages")
        
        messagesRef
            .whereField("senderID", isNotEqualTo: userID)
            .whereField("isSeen", isEqualTo: false)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching unread count: \(error)")
                    completion(0)
                    return
                }
                
                let unreadCount = snapshot?.documents.count
                completion(unreadCount ?? 0)
            }
    }
}

extension ChatListVC: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let isInitialEmpty = chatRooms.isEmpty
        let isSearchEmpty = filteredChatRooms.isEmpty
        
        if !isInitialEmpty && isSearchEmpty {
            noSearchResultsView.isHidden = false
        } else {
            noSearchResultsView.isHidden = true
        }
        
        return isLoading ? 10 : filteredChatRooms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatListCell", for: indexPath) as! ChatListCell
        
        if isLoading {
            cell.isSkeleton = true
        } else {
            let chatRoom = filteredChatRooms[indexPath.row]
            let lastMessage = chatRoom.lastMessage ?? "沒有消息"
            let lastMessageTime = chatRoom.lastMessageTimestamp?.dateValue().formattedChatDate() ?? ""
            
            if let participant = participants[chatRoom.id] {
                let unreadCount = unreadCounts[chatRoom.id] ?? 0
                cell.configure(
                    name: participant.fullName,
                    lastMessage: lastMessage,
                    time: lastMessageTime,
                    image: participant.photoURL ?? "",
                    unreadCount: unreadCount
                )
            }
        }
        cell.backgroundColor = .myBackground
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        
        let selectedChatRoom = filteredChatRooms[indexPath.row]
        let chatVC = ChatVC()
        
        if let userRole = UserDefaults.standard.string(forKey: "userRole") {
            if userRole == "teacher" {
                if let student = participants[selectedChatRoom.id] as? Student {
                    chatVC.student = student
                }
            } else {
                if let teacher = participants[selectedChatRoom.id] as? Teacher {
                    chatVC.teacher = teacher
                }
            }
        }
        
        isDataReloadNeeded = false
        if let cell = tableView.cellForRow(at: indexPath) as? ChatListCell {
            cell.updateUnreadCount(0)
        }
        
        navigationController?.pushViewController(chatVC, animated: true)
    }
}

extension ChatListVC: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        searchBarView.hideKeyboardAndCancel()
    }
}

extension ChatListVC: SearchBarViewDelegate {
    func searchBarView(_ searchBarView: SearchBarView, didChangeText text: String) {
        if text.isEmpty {
            filteredChatRooms = chatRooms.filter { self.participants[$0.id] != nil }
        } else {
            filteredChatRooms = chatRooms.filter { chatRoom in
                if let participant = participants[chatRoom.id] {
                    return participant.fullName.lowercased().contains(text.lowercased())
                }
                return false
            }
        }
        tableView.reloadData()
    }
    
    func searchBarViewDidCancel(_ searchBarView: SearchBarView) {
        filteredChatRooms = chatRooms
        tableView.reloadData()
    }
}
