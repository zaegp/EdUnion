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
    var userID: String? {
        return UserSession.shared.currentUserID
    }
    
    var onDataUpdate: (() -> Void)?
    
    func fetchData() {
        guard let userID = userID else {
            print("User ID is nil.")
            return
        }
        
        print(userID)
        UserFirebaseService.shared.fetchFollowedTeachers(forStudentID: userID) { result in
            switch result {
            case .success(let teachers):
                if teachers.isEmpty {
                    self.items = []
                    self.filteredItems = []
                    print("No followed teachers found.")
                } else {
                    print("Fetched teachers: \(teachers)")
                    self.items = teachers
                    self.filteredItems = teachers
                }
                
                // 確保在主執行緒更新 UI
                DispatchQueue.main.async {
                    self.onDataUpdate?() // 通知 UI 更新
                }
                
            case .failure(let error):
                print("Failed to fetch teachers: \(error)")
                
                // 處理錯誤的情況，確保 items 和 filteredItems 都被清空
                DispatchQueue.main.async {
                    self.items = []
                    self.filteredItems = []
                    self.onDataUpdate?() // 通知 UI 更新
                }
            }
        }
    }
    
    func search(query: String) {
        if query.isEmpty {
            filteredItems = items
        } else {
            filteredItems = items.filter { teacher in
                // 安全處理 resume 陣列，防止越界崩潰
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
