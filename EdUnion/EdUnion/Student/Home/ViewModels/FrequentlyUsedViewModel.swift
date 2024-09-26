//
//  FrequentlyUsedViewModel.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/23.
//

import Foundation

class FrequentlyUsedViewModel: BaseCollectionViewModelProtocol {
    
    var items: [Teacher] = []
    private var filteredItems: [Teacher] = []
    
    var onDataUpdate: (() -> Void)?
    
    func fetchData() {
        UserFirebaseService.shared.fetchFrequentlyUsedTeachers(forStudentID: studentID) { result in
            switch result {
            case .success(let teachers):
                self.items = teachers
                self.filteredItems = teachers
                self.onDataUpdate?()
            case .failure(let error):
                print("Failed to fetch teachers: \(error)")
            }
        }
    }
    
    func search(query: String) {
        if query.isEmpty {
            filteredItems = items
        } else {
            filteredItems = items.filter { teacher in
                teacher.fullName.lowercased().contains(query.lowercased()) ||
                teacher.resume[0].lowercased().contains(query.lowercased()) ||
                teacher.resume[1].lowercased().contains(query.lowercased()) ||
                teacher.resume[2].lowercased().contains(query.lowercased()) ||
                teacher.resume[3].lowercased().contains(query.lowercased())
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
    
    private func fetchFollowedTeachers() -> [Teacher] {
        return []
    }
}
