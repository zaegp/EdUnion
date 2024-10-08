//
//  BaseCalendarViewModel.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/21.
//

import SwiftUI

class BaseCalendarViewModel: ObservableObject {
    @Published var participantNames: [String: String] = [:]
    @Published var sortedActivities: [Appointment] = []
    
    func loadAndSortActivities(for activities: [Appointment]) {
            sortActivities(by: activities)
        }
    
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
    
    func sortActivities(by activities: [Appointment], ascending: Bool = false) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm" // 根據實際格式調整

        sortedActivities = activities.sorted { (a, b) -> Bool in
            // 提取開始時間部分
            guard let timeAFull = a.times.first,
                  let timeBFull = b.times.first,
                  let startTimeAString = timeAFull.split(separator: "-").first?.trimmingCharacters(in: .whitespaces),
                  let startTimeBString = timeBFull.split(separator: "-").first?.trimmingCharacters(in: .whitespaces),
                  let dateA = dateFormatter.date(from: startTimeAString),
                  let dateB = dateFormatter.date(from: startTimeBString) else {
                return false
            }
            return ascending ? dateA > dateB : dateA < dateB
        }
        print("Activities sorted: \(sortedActivities.map { $0.times.first ?? "" })")
    }
}
