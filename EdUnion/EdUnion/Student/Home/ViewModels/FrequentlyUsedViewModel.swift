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
        guard let userID = UserSession.shared.currentUserID else {
            print("User ID is nil.")
            return
        }
        
        fetchBlocklist { [weak self] blocklist in
            self?.blocklist = blocklist
            UserFirebaseService.shared.fetchTeacherList(forStudentID: userID, listKey: "usedList") { result in
                switch result {
                case .success(let teachers):
                    let filteredTeachers = teachers.filter { !blocklist.contains($0.id) }
                    self?.items = filteredTeachers
                    self?.filteredItems = filteredTeachers
                    self?.onDataUpdate?()
                case .failure(let error):
                    print("Failed to fetch teachers: \(error)")
                    self?.items = []
                    self?.filteredItems = []
                    self?.onDataUpdate?()
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
