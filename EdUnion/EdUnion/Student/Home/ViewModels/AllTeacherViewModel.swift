//
//  StudentHomeViewModel.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/14.
//

import Foundation

class AllTeacherViewModel: BaseCollectionViewModelProtocol {
    
    var items: [Teacher] = []
    var onDataUpdate: (() -> Void)?
    
    func fetchData() {
        UserFirebaseService.shared.fetchTeachers { [weak self] result in
            switch result {
            case .success(let teachers):
                self?.items = teachers
                print(teachers)
                self?.onDataUpdate?()
            case .failure(let error):
                print("Error fetching teachers: \(error)")
            }
        }
    }
    
    func numberOfItems() -> Int {
        return items.count
    }
    
    func item(at index: Int) -> Teacher {
        return items[index]
    }
}
