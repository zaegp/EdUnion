//
//  BaseCollectionViewModelProtocol.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/10/18.
//

protocol BaseCollectionViewModelProtocol {
    var items: [Teacher] { get set }
    var onDataUpdate: (() -> Void)? { get set }
    var userID: String { get }

    func fetchData()
    func numberOfItems() -> Int
    func item(at index: Int) -> Teacher
    
    func search(query: String)
}

extension BaseCollectionViewModelProtocol {
    var userID: String {
            return UserSession.shared.unwrappedUserID
        }
    
    func fetchBlocklist(completion: @escaping ([String]) -> Void) {
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
    
    func filteredTeachers(by query: String) -> [Teacher] {
        if query.isEmpty {
            return items
        } else {
            return items.filter { teacher in
                teacher.fullName.lowercased().contains(query.lowercased()) ||
                teacher.resume.prefix(4).contains { $0.lowercased().contains(query.lowercased()) }
            }
        }
    }
    
    func numberOfItems(in filteredItems: [Teacher]) -> Int {
        return filteredItems.count
    }
    
    func item(at index: Int, in filteredItems: [Teacher]) -> Teacher {
        return filteredItems[index]
    }
}
