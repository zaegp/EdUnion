//
//  StudentHomeViewModel.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/14.
//

import Foundation

class StudentHomeViewModel {
    
    private var teachers: [Teacher] = []
    var onDataUpdate: (() -> Void)?
    
    func fetchTeachers() {
        FirebaseService.shared.fetchTeachers { [weak self] result in
            switch result {
            case .success(let teachers):
                self?.teachers = teachers
                print(teachers)
                self?.onDataUpdate?()
            case .failure(let error):
                print("Error fetching teachers: \(error)")
            }
        }
    }
    
    func numberOfTeachers() -> Int {
        return teachers.count
    }
    
    func teacher(at index: Int) -> Teacher {
        return teachers[index]
    }
}

