//
//  FrequentlyUsedViewModel.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/23.
//

import Foundation

class FrequentlyUsedViewModel: BaseCollectionViewModelProtocol {
    var items: [Teacher] = []
    
    var onDataUpdate: (() -> Void)?
    
    func fetchData() {
        UserFirebaseService.shared.fetchFrequentlyUsedTeachers(forStudentID: studentID) { result in
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
        return []
    }
}
