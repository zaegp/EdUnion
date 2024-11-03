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
    private var blocklist: [String] = []
    private var listener: ListenerRegistration?

    deinit {
        listener?.remove()
    }

    func fetchData() {
        fetchBlocklist { [weak self] blocklist in
            guard let self = self else { return }
            self.blocklist = blocklist
            self.fetchTeachers()
        }
    }

    private func fetchTeachers() {
        listener = UserFirebaseService.shared.fetchTeachersRealTime { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let teachers):
                self.items = self.filteredTeachers(from: teachers)
                self.filteredItems = self.items
                self.onDataUpdate?()
            case .failure(let error):
                print("獲取老師資料時出錯：\(error)")
            }
        }
    }

    private func filteredTeachers(from teachers: [Teacher]) -> [Teacher] {
        return teachers.filter { teacher in
            !blocklist.contains(teacher.id) &&
            teacher.id != userID &&
            !teacher.fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    func search(query: String) {
        filteredItems = filteredTeachers(by: query)
        onDataUpdate?()
    }

    func numberOfItems() -> Int {
        return filteredItems.count
    }

    func item(at index: Int) -> Teacher {
        return filteredItems[index]
    }
}
