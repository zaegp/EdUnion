//
//  FollowViewModel.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/21.
//

class FollowViewModel: BaseCollectionViewModelProtocol {
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
                UserFirebaseService.shared.fetchTeacherList(forStudentID: userID, listKey: "followList") { result in
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
    
    func search(query: String) {
        if query.isEmpty {
            filteredItems = items
        } else {
            filteredItems = items.filter { teacher in
                return teacher.fullName.lowercased().contains(query.lowercased()) ||
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
