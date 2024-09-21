//
//  StudentHomeViewModel.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/14.
//

import Foundation

//class StudentHomeViewModel {
//    
//    private var teachers: [Teacher] = []
//    var onDataUpdate: (() -> Void)?
//    
//    func fetchTeachers() {
//        UserFirebaseService.shared.fetchTeachers { [weak self] result in
//            switch result {
//            case .success(let teachers):
//                self?.teachers = teachers
//                print(teachers)
//                self?.onDataUpdate?()
//            case .failure(let error):
//                print("Error fetching teachers: \(error)")
//            }
//        }
//    }
//    
//    func numberOfTeachers() -> Int {
//        return teachers.count
//    }
//    
//    func teacher(at index: Int) -> Teacher {
//        return teachers[index]
//    }
//}

class StudentHomeViewModel: BaseCollectionViewModelProtocol {
    
    var items: [Teacher] = []  // 根據協議定義的屬性
    var onDataUpdate: (() -> Void)?
    
    // 遵守協議，實現 fetchData 方法來加載所有教師數據
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
