//
//  FrequentlyUsedViewModel.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/23.
//

class FrequentlyUsedViewModel: BaseCollectionViewModelProtocol {
    var items: [Teacher] = []
    private var filteredItems: [Teacher] = []
    private var blocklist: [String] = []
    var onDataUpdate: (() -> Void)?
    
    func fetchData() {
        fetchBlocklist { [weak self] blocklist in
            guard let self = self else { return }
            self.blocklist = blocklist
            self.fetchTeachers()
        }
    }
    
    private func fetchTeachers() {
        UserFirebaseService.shared.fetchTeacherList(forStudentID: userID, listKey: "usedList") { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let teachers):
                self.updateTeachers(with: teachers)
            case .failure(let error):
                print("Failed to fetch teachers: \(error)")
                self.clearTeachers()
            }
        }
    }

    private func updateTeachers(with teachers: [Teacher]) {
        let filteredTeachers = teachers.filter { !blocklist.contains($0.id) }
        items = filteredTeachers
        filteredItems = filteredTeachers
        onDataUpdate?()
    }
    
    private func clearTeachers() {
        items = []
        filteredItems = []
        onDataUpdate?()
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
        filteredItems = query.isEmpty ? items : filteredTeachers(by: query)
        onDataUpdate?()
    }
    
    private func filteredTeachers(by query: String) -> [Teacher] {
        return items.filter { teacher in
            teacher.fullName.lowercased().contains(query.lowercased()) ||
            teacher.resume.prefix(4).contains { $0.lowercased().contains(query.lowercased()) }
        }
    }

    func numberOfItems() -> Int {
        return filteredItems.count
    }
    
    func item(at index: Int) -> Teacher {
        return filteredItems[index]
    }
}
