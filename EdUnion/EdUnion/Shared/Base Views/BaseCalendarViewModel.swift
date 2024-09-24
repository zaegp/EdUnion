//
//  BaseCalendarViewModel.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/21.
//

import SwiftUI

class BaseCalendarViewModel: ObservableObject {
    
    @Published var studentNames: [String: String] = [:]  // 儲存學生的名字
    @Published var teacherNames: [String: String] = [:]  // 儲存老師的名字
    
    // 用於根據學生ID查詢名稱
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
    
    // 用於根據老師ID查詢名稱
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
