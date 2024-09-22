//
//  BaseCalendarViewModel.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/21.
//

import SwiftUI

class BaseCalendarViewModel: ObservableObject {
    
    @Published var studentNames: [String: String] = [:]  // 儲存學生的名字
    
    func fetchStudentName(for studentID: String) {
        UserFirebaseService.shared.fetchName(from: "students", by: studentID) { result in
            switch result {
            case .success(let studentName):
                DispatchQueue.main.async {
                    self.studentNames[studentID] = studentName ?? "Unknown Student"
                }
            case .failure:
                DispatchQueue.main.async {
                    self.studentNames[studentID] = "Unknown Student"
                }
            }
        }
    }
}
