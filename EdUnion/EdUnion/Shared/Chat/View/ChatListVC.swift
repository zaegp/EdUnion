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
    
    private var chatRooms: [ChatRoom] = []
    private var filteredChatRooms: [ChatRoom] = []
    private var participantID: String?
    private var participants: [String: UserProtocol] = [:]
    private let tableView = UITableView()
    private let searchBarView = SearchBarView()

    private var chatRoomListener: ListenerRegistration?
    
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
        view.backgroundColor = .myBackground
        
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
        navigationController?.navigationBar.barTintColor = .myBackground
        navigationController?.navigationBar.shadowImage = UIImage()

        tabBarController?.tabBar.isHidden = true
        if let tabBarController = self.tabBarController as? TabBarController {
            tabBarController.setCustomTabBarHidden(false, animated: true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        chatRoomListener?.remove()
    }
    
    private func setupUI() {
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
        noChatRoomsView.isHidden = true
        noSearchResultsView.isHidden = true

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
            self?.filteredChatRooms = chatRooms

            let dispatchGroup = DispatchGroup()

            for chatRoom in chatRooms {
                dispatchGroup.enter()
                let participantId = chatRoom.participants.filter { $0 != self?.participantID }.first ?? "未知用戶"

                if isTeacher {
                    UserFirebaseService.shared.fetchUser(from: "students", by: participantId, as: Student.self) { [weak self] result in
                        switch result {
                        case .success(let student):
                            self?.participants[chatRoom.id] = student
                        case .failure:
                            let unknownStudent = Student.self
                            self?.participants[chatRoom.id] = Student.self as? any UserProtocol
                        }
                        dispatchGroup.leave()
                    }
                } else {
                    UserFirebaseService.shared.fetchUser(from: "teachers", by: participantId, as: Teacher.self) { [weak self] result in
                        switch result {
                        case .success(let teacher):
                            self?.participants[chatRoom.id] = teacher
                        case .failure:
                            self?.participants[chatRoom.id] = Teacher.self as? any UserProtocol
                        }
                        dispatchGroup.leave()
                    }
                }
            }

            dispatchGroup.notify(queue: .main) {
                if chatRooms.isEmpty {
                    self?.noChatRoomsView.isHidden = false
                } else {
                    self?.noChatRoomsView.isHidden = true
                }
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
        let isInitialEmpty = chatRooms.isEmpty
        let isSearchEmpty = filteredChatRooms.isEmpty
        
        if !isInitialEmpty && isSearchEmpty {
            noSearchResultsView.isHidden = false
        } else {
            noSearchResultsView.isHidden = true
        }
        
        return filteredChatRooms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ChatListCell = tableView.dequeueReusableCell(withIdentifier: "ChatListCell", for: indexPath) 
        cell.backgroundColor = .myBackground
        let chatRoom = filteredChatRooms[indexPath.row]
        
        let lastMessage = chatRoom.lastMessage ?? "沒有消息"
        let lastMessageTime = chatRoom.lastMessageTimestamp?.dateValue().formattedChatDate() ?? ""
        
        if let participant = participants[chatRoom.id] {
            let photoURLString = participant.photoURL ?? ""
            cell.configure(name: participant.fullName, lastMessage: lastMessage, time: lastMessageTime, image: photoURLString)
        } else {
            cell.configure(name: "未知用户", lastMessage: lastMessage, time: lastMessageTime, image: "")
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

extension ChatListVC: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        searchBarView.hideKeyboardAndCancel()
    }
}

extension ChatListVC: SearchBarViewDelegate {
    func searchBarView(_ searchBarView: SearchBarView, didChangeText text: String) {
        if text.isEmpty {
            filteredChatRooms = chatRooms
        } else {
            filteredChatRooms = chatRooms.filter { chatRoom in
                if let participantName = participants[chatRoom.id] as? String {
                    return participantName.lowercased().contains(text.lowercased())
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
