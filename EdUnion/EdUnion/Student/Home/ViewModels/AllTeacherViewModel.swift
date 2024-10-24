//
//  StudentHomeViewModel.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/14.
//

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
            _ = UserFirebaseService.shared.fetchTeachersRealTime { [weak self] result in
                switch result {
                case .success(let teachers):
                    self?.items = teachers.filter { teacher in
                        !blocklist.contains(teacher.id) &&
                        !teacher.fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    }
                    self?.filteredItems = self?.items ?? []
                    self?.onDataUpdate?()
                case .failure(let error):
                    print("Error fetching teachers: \(error)")
                }
            }
        }
    }
    
    func search(query: String) {
        filteredItems = filteredTeachers(by: query)
        onDataUpdate?()
    }
    
    func numberOfItems() -> Int {
        return numberOfItems(in: filteredItems)
    }
    
    func item(at index: Int) -> Teacher {
        return item(at: index, in: filteredItems)
    }
}
