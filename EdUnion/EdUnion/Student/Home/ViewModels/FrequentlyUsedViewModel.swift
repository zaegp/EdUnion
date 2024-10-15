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
    private var blocklist: [String] = []
    let userID = UserSession.shared.currentUserID
    
    var onDataUpdate: (() -> Void)?
    
    func fetchData() {
        fetchBlocklist { [weak self] blocklist in
            self?.blocklist = blocklist
            
            UserFirebaseService.shared.fetchTeacherList(forStudentID: self?.userID ?? "", listKey: "usedList") { result in
                switch result {
                case .success(let teachers):
                    self?.items = teachers.filter { !blocklist.contains($0.id ?? "") }
                    self?.filteredItems = self?.items ?? []
                    self?.onDataUpdate?()
                case .failure(let error):
                    print("Failed to fetch teachers: \(error)")
                }
            }
        }
    }
    
    private func fetchBlocklist(completion: @escaping ([String]) -> Void) {
        UserFirebaseService.shared.fetchBlocklist { result in
            switch result {
            case .success(let blocklist):
                completion(blocklist)
            case .failure(let error):
                print("Error fetching blocklist: \(error)")
                completion([])
            }
        }
    }
    
    func search(query: String) {
        if query.isEmpty {
            filteredItems = items
        } else {
            filteredItems = items.filter { teacher in
                teacher.fullName.lowercased().contains(query.lowercased()) ||
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
