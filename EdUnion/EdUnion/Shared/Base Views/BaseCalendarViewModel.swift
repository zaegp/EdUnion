//
//  BaseCalendarViewModel.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/21.
//

import SwiftUI
import FirebaseFirestore

class BaseCalendarViewModel: ObservableObject {
    @Published var participantNames: [String: String] = [:]
    @Published var sortedActivities: [Appointment] = []
    
    var students: [Student] = []
    @Published var studentsNotes: [String: String] = [:]
    
    var onDataUpdated: (() -> Void)?
    
    
    func loadAndSortActivities(for activities: [Appointment]) {
            sortActivities(by: activities)
        }
    
    func fetchUserData<T: UserProtocol & Decodable>(from collection: String, userID: String, as type: T.Type, completion: (() -> Void)? = nil) {
        UserFirebaseService.shared.fetchUser(from: collection, by: userID, as: type) { [weak self] result in
            switch result {
            case .success(let user):
                DispatchQueue.main.async {
                    if let student = user as? Student {
                        self?.participantNames[userID] = student.fullName.isEmpty ? "未知学生" : student.fullName
                    } else if let teacher = user as? Teacher {
                        self?.participantNames[userID] = teacher.fullName.isEmpty ? "未知老师" : teacher.fullName
                    }
                    completion?()
                }
            case .failure:
                DispatchQueue.main.async {
                    let unknownLabel = collection == "students" ? "未知学生" : "未知老师"
                    self?.participantNames[userID] = unknownLabel
                    completion?()
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
    
    func saveNoteText(_ noteText: String, for studentID: String, teacherID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        UserFirebaseService.shared.updateStudentNotes(forTeacher: teacherID, studentID: studentID, note: noteText) { [weak self] result in
            switch result {
            case .success:
                self?.studentsNotes[studentID] = noteText
                self?.onDataUpdated?()
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func fetchStudents(for teacherID: String) {
        UserFirebaseService.shared.fetchTeacherStudentList(teacherID: teacherID) { [weak self] result in
            switch result {
            case .success(let studentsNotes):
                self?.studentsNotes = studentsNotes
                self?.handleFetchedData(studentsNotes)
            case .failure(let error):
                print("取得學生資料失敗: \(error.localizedDescription)")
            }
        }
    }
    
    private func handleFetchedData(_ studentsNotes: [String: String]) {
        var fetchedStudents: [Student] = []
        let dispatchGroup = DispatchGroup()
        
        for (studentID, _) in studentsNotes {
            dispatchGroup.enter()
            
            UserFirebaseService.shared.fetchUser(from: "students", by: studentID, as: Student.self) { result in
                defer { dispatchGroup.leave() }
                
                switch result {
                case .success(let student):
                    fetchedStudents.append(student)
                case .failure(let error):
                    print("取得學生 \(studentID) 資料失敗: \(error.localizedDescription)")
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.students = fetchedStudents
            self.onDataUpdated?()
        }
    }
}
