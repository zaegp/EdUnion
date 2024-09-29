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
    private var participants: [String: Any] = [:]
    private var chatRoomListener: ListenerRegistration?
    
    var theTeacher: Teacher?
    var theStudent: Student?
    
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
        tableView.separatorStyle = .none
        
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
        tableView.register(ChatListCell.self, forCellReuseIdentifier: "ChatListCell")
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
        guard let userRole = UserDefaults.standard.string(forKey: "userRole") else {
                print("Error: Unable to get user role from UserDefaults.")
                return
            }
            
            let isTeacher = (userRole == "teacher")
        
        UserFirebaseService.shared.fetchChatRooms(for: participantID ?? "", isTeacher: isTeacher) { [weak self] (chatRooms, error) in
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
                                self?.participants[chatRoom.id] = studentName
                            case .failure:
                                self?.participants[chatRoom.id] = "Unknown Student"
                            }
                            DispatchQueue.main.async {
                                self?.tableView.reloadData()
                            }
                        }
                    } else if userRole == "teacher" {
                        UserFirebaseService.shared.fetchName(from: "teachers", by: participantId) { [weak self] result in
                            switch result {
                            case .success(let teacherName):
                                self?.participants[chatRoom.id] = teacherName
                            case .failure:
                                self?.participants[chatRoom.id] = "Unknown Teacher"
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatListCell", for: indexPath) as! ChatListCell
        let chatRoom = filteredChatRooms[indexPath.row]
        
        let participantId = chatRoom.participants.filter { $0 != participantID }.first ?? "未知用戶"
        let lastMessage = chatRoom.lastMessage ?? "沒有消息"
        let lastMessageTime = chatRoom.lastMessageTimestamp?.dateValue().formattedChatDate() ?? ""
        
        let userRole = UserDefaults.standard.string(forKey: "userRole") ?? "student"
        
        if userRole == "teacher" {
            UserFirebaseService.shared.fetchUser(from: "students", by: participantId, as: Student.self) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let student):
                        self.participants[chatRoom.id] = student
                        cell.configure(name: student.fullName, lastMessage: lastMessage, time: lastMessageTime, image: student.photoURL ?? "")
                    case .failure:
                        cell.configure(name: "Unknown Student", lastMessage: lastMessage, time: lastMessageTime, image: "")
                    }
                }
            }
        } else {
            UserFirebaseService.shared.fetchUser(from: "teachers", by: participantId, as: Teacher.self) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let teacher):
                        self.participants[chatRoom.id] = teacher
                        cell.configure(name: teacher.fullName, lastMessage: lastMessage, time: lastMessageTime, image: teacher.photoURL ?? "")
                    case .failure:
                        cell.configure(name: "Unknown Teacher", lastMessage: lastMessage, time: lastMessageTime, image: "")
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
        
        navigationController?.pushViewController(chatVC, animated: true)
    }
}

extension ChatListVC: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredChatRooms = chatRooms
        } else {
            filteredChatRooms = chatRooms.filter { chatRoom in
                if let participantName = participants[chatRoom.id] as? String {
                    return participantName.lowercased().contains(searchText.lowercased())
                }
                return false
            }
        }
        tableView.reloadData()
    }
}
