//
//  AllStudentVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/23.
//

import UIKit

class AllStudentVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private let tableView = UITableView()
        private var students: [Student] = [] // 假設你有一個 `Student` 模型

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
            // 從 Firebase 獲取學生資料
            UserFirebaseService.shared.fetchTeacherStudentList(teacherID: teacherID) { [weak self] result in
                switch result {
                case .success(let studentsNotes):
                    // 成功取得 studentsNotes 字典，可以進一步處理
                    self?.handleFetchedData(studentsNotes)
                case .failure(let error):
                    // 取得失敗，處理錯誤
                    print("取得學生資料失敗: \(error.localizedDescription)")
                }
            }
        }
    
    private func handleFetchedData(_ studentsNotes: [String: String]) {
        // 清空已存在的學生資料
        students.removeAll()
        
        let dispatchGroup = DispatchGroup()  // 用來同步處理多個 Firebase 請求
        
        for (studentID, _) in studentsNotes {
            dispatchGroup.enter()  // 開始一個請求
            
            UserFirebaseService.shared.fetchStudent(by: studentID) { [weak self] result in
                switch result {
                case .success(let student):
                    // 更新學生資料
                    self?.students.append(student)
                case .failure(let error):
                    print("取得學生 \(studentID) 資料失敗: \(error.localizedDescription)")
                }
                dispatchGroup.leave()  // 完成一個請求
            }
        }
        
        // 當所有請求完成時更新 UI
        dispatchGroup.notify(queue: .main) {
            self.updateUI()
        }
    }

    private func updateUI() {
        // 刷新 UITableView 或其他 UI 元件
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
