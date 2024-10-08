//
//  FollowViewModel.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/21.
//

import Foundation

class FollowViewModel: BaseCollectionViewModelProtocol {
    var items: [Teacher] = []
    private var filteredItems: [Teacher] = []
    private var blocklist: [String] = [] // 存儲 blocklist 中的老師 ID
    
    var userID: String? {
        return UserSession.shared.currentUserID
    }
    
    var onDataUpdate: (() -> Void)?
    
    func fetchData() {
        guard let userID = userID else {
            print("User ID is nil.")
            return
        }
        
        // 先取得 blocklist
        fetchBlocklist { [weak self] blocklist in
            self?.blocklist = blocklist
            
            // 然後再獲取關注的老師
            UserFirebaseService.shared.fetchFollowedTeachers(forStudentID: userID) { result in
                switch result {
                case .success(let teachers):
                    // 過濾 blocklist 中的老師
                    let filteredTeachers = teachers.filter { !blocklist.contains($0.id ?? "") }
                    
                    if filteredTeachers.isEmpty {
                        self?.items = []
                        self?.filteredItems = []
                        print("No followed teachers found.")
                    } else {
                        print("Fetched teachers: \(filteredTeachers)")
                        self?.items = filteredTeachers
                        self?.filteredItems = filteredTeachers
                    }
                    
                    DispatchQueue.main.async {
                        self?.onDataUpdate?()
                    }
                    
                case .failure(let error):
                    print("Failed to fetch teachers: \(error)")
                    
                    DispatchQueue.main.async {
                        self?.items = []
                        self?.filteredItems = []
                        self?.onDataUpdate?()
                    }
                }
            }
        }
    }
    
    // 新增方法來取得 blocklist
    private func fetchBlocklist(completion: @escaping ([String]) -> Void) {
        UserFirebaseService.shared.fetchBlocklist { result in
            switch result {
            case .success(let blocklist):
                completion(blocklist)
            case .failure(let error):
                print("Error fetching blocklist: \(error)")
                completion([])
            }
        }
    }
    
    func search(query: String) {
        if query.isEmpty {
            filteredItems = items
        } else {
            filteredItems = items.filter { teacher in
                return teacher.fullName.lowercased().contains(query.lowercased()) ||
                teacher.resume.prefix(4).contains { $0.lowercased().contains(query.lowercased()) }
            }
        }
        onDataUpdate?()
    }
    
    func numberOfItems() -> Int {
        return filteredItems.count
    }
    
    func item(at index: Int) -> Teacher {
        return filteredItems[index]
    }
}
