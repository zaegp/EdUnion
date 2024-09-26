//
//  AllStudentVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/23.
//

import UIKit

class AllStudentVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private let tableView = UITableView()
        private var students: [Student] = []

        override func viewDidLoad() {
            super.viewDidLoad()
            
            view.backgroundColor = .white
            setupTableView()
            fetchStudents()
        }

        func setupTableView() {
            view.addSubview(tableView)
            
            tableView.delegate = self
            tableView.dataSource = self
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: "studentCell")
            
            tableView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                tableView.topAnchor.constraint(equalTo: view.topAnchor),
                tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
                tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
                tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }

        func fetchStudents() {
            UserFirebaseService.shared.fetchTeacherStudentList(teacherID: teacherID) { [weak self] result in
                switch result {
                case .success(let studentsNotes):
                    self?.handleFetchedData(studentsNotes)
                case .failure(let error):
                    print("取得學生資料失敗: \(error.localizedDescription)")
                }
            }
        }
    
    private func handleFetchedData(_ studentsNotes: [String: String]) {
        students.removeAll()
        
        let dispatchGroup = DispatchGroup()
        
        for (studentID, _) in studentsNotes {
            dispatchGroup.enter()
            
            UserFirebaseService.shared.fetchStudent(by: studentID) { [weak self] result in
                switch result {
                case .success(let student):
                    self?.students.append(student)
                case .failure(let error):
                    print("取得學生 \(studentID) 資料失敗: \(error.localizedDescription)")
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.updateUI()
        }
    }

    private func updateUI() {
        tableView.reloadData()
    }
    
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return students.count
        }

        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "studentCell", for: indexPath)
            let student = students[indexPath.row]
                cell.textLabel?.text = student.name
            return cell
        }
}
