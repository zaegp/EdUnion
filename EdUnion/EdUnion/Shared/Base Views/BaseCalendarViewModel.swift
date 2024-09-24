//
//  BaseCalendarViewModel.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/21.
//

import SwiftUI

class BaseCalendarViewModel: ObservableObject {
    
    @Published var studentNames: [String: String] = [:]
    @Published var teacherNames: [String: String] = [:]
    
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
    
    func fetchTeacherName(for teacherID: String) {
        UserFirebaseService.shared.fetchName(from: "teachers", by: teacherID) { result in
            switch result {
            case .success(let teacherName):
                DispatchQueue.main.async {
                    self.teacherNames[teacherID] = teacherName ?? "Unknown Teacher"
                }
            case .failure:
                DispatchQueue.main.async {
                    self.teacherNames[teacherID] = "Unknown Teacher"
                }
            }
        }
    }
}
