//
//  StudentHomeViewModel.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/14.
//

import Foundation
import FirebaseFirestore

class AllTeacherViewModel: BaseCollectionViewModelProtocol {
    
    var items: [Teacher] = []
    var filteredItems: [Teacher] = []
    var onDataUpdate: (() -> Void)?
    private var listener: ListenerRegistration?
    
    deinit {
        listener?.remove()
    }
    
    func fetchData() {
        UserFirebaseService.shared.fetchTeachersRealTime { [weak self] result in
            switch result {
            case .success(let teachers):
                self?.items = teachers
                self?.filteredItems = teachers
                self?.onDataUpdate?()
            case .failure(let error):
                print("Error fetching teachers: \(error)")
            }
        }
    }
    
    func search(query: String) {
        if query.isEmpty {
            filteredItems = items
        } else {
            filteredItems = items.filter { teacher in
                // 搜尋名字和 resume 屬性
                teacher.name.lowercased().contains(query.lowercased()) ||
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
}
