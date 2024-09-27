//
//  BaseCalendarViewModel.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/21.
//

import SwiftUI

class BaseCalendarViewModel: ObservableObject {
    @Published var participantNames: [String: String] = [:]

    func fetchUserData<T: UserProtocol & Decodable>(from collection: String, userID: String, as type: T.Type) {
        UserFirebaseService.shared.fetchUser(from: collection, by: userID, as: type) { [weak self] result in
            switch result {
            case .success(let user):
                DispatchQueue.main.async {
                    if let student = user as? Student {
                        self?.participantNames[userID] = student.fullName.isEmpty ? "Unknown Student" : student.fullName
                    } else if let teacher = user as? Teacher {
                        self?.participantNames[userID] = teacher.fullName.isEmpty ? "Unknown Teacher" : teacher.fullName
                    }
                }
            case .failure:
                DispatchQueue.main.async {
                    let unknownLabel = collection == "students" ? "Unknown Student" : "Unknown Teacher"
                    self?.participantNames[userID] = unknownLabel
                }
            }
        }
    }
}
