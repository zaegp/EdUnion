//
//  StudentListViewModel.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/10/9.
//

import Foundation

class StudentListViewModel {
    var students: [Student] = []
    var studentsNotes: [String: String] = [:]
    
    var onDataUpdated: (() -> Void)?
    
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
            
            UserFirebaseService.shared.fetchUser(from: Constants.studentsCollection, by: studentID, as: Student.self) { result in
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
    
    func saveNoteText(_ noteText: String, for student: Student, teacherID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        UserFirebaseService.shared.updateStudentNotes(studentID: student.id, note: noteText) { [weak self] result in
            switch result {
            case .success:
                self?.studentsNotes[student.id] = noteText
                self?.onDataUpdated?()
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func blockStudent(_ student: Student, teacherID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        UserFirebaseService.shared.blockUser(blockID: student.id, userCollection: Constants.teachersCollection) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            UserFirebaseService.shared.removeStudentFromTeacherNotes(teacherID: teacherID, studentID: student.id) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    if let index = self.students.firstIndex(where: { $0.id == student.id }) {
                        self.students.remove(at: index)
                        self.onDataUpdated?()
                    }
                    completion(.success(()))
                }
            }
        }
    }
}
