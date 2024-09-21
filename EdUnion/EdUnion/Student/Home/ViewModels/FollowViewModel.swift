//
//  FollowViewModel.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/21.
//

import Foundation

class FollowViewModel: BaseCollectionViewModelProtocol {
    var items: [Teacher] = []
    
    var onDataUpdate: (() -> Void)?
    
    func fetchData() {
        UserFirebaseService.shared.fetchFollowedTeachers(forStudentID: studentID) { result in
            switch result {
            case .success(let teachers):
                print("Fetched teachers: \(teachers)")
                self.items = teachers
                self.onDataUpdate?()
            case .failure(let error):
                print("Failed to fetch teachers: \(error)")
            }
        }
    }
    
    func numberOfItems() -> Int {
        return items.count
    }
    
    func item(at index: Int) -> Teacher {
        return items[index]
    }
    
    private func fetchFollowedTeachers() -> [Teacher] {
        // 從數據源加載關注的老師列表
        return []  // 返回測試數據或實際數據
    }
}
