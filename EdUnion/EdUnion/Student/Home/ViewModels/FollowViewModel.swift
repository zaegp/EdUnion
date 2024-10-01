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
                
                DispatchQueue.main.async {
                    self.onDataUpdate?()
                }
                
            case .failure(let error):
                print("Failed to fetch teachers: \(error)")
                
                DispatchQueue.main.async {
                    self.items = []
                    self.filteredItems = []
                    self.onDataUpdate?()
                }
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
