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
    var onDataUpdate: (() -> Void)?
    private var listener: ListenerRegistration?
        
        deinit {
            // 移除實時監聽，防止內存泄漏
            listener?.remove()
        }

    
    func fetchData() {
        UserFirebaseService.shared.fetchTeachersRealTime { [weak self] result in
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
