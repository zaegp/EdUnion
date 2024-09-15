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
                print(self?.teachers)
                self?.onDataUpdate?()  // 通知 VC 刷新 UI
            case .failure(let error):
                print("Error fetching teachers: \(error)")
            }
        }
    }

    // 返回老師的數量
    func numberOfTeachers() -> Int {
        return teachers.count
    }

    // 根據索引返回某個老師的資料
    func teacher(at index: Int) -> Teacher {
        return teachers[index]
    }
}

