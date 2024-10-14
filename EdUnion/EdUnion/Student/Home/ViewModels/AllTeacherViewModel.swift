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
    private var blocklist: [String] = []
    
    deinit {
        listener?.remove()
    }
    
    func fetchData() {
        fetchBlocklist { [weak self] blocklist in
            self?.blocklist = blocklist
            print(blocklist)
            UserFirebaseService.shared.fetchTeachersRealTime { [weak self] result in
                switch result {
                case .success(let teachers):
                    self?.items = teachers.filter {
                        !blocklist.contains($0.id ?? "") && !($0.fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
                    }
                    self?.filteredItems = self?.items ?? []
                    self?.onDataUpdate?()
                case .failure(let error):
                    print("Error fetching teachers: \(error)")
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
