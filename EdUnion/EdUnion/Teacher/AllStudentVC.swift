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
    let userID = UserSession.shared.currentUserID
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        setupTableView()
        fetchStudents()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tabBarController?.tabBar.isHidden = true
        if let tabBarController = self.tabBarController as? TabBarController {
            tabBarController.setCustomTabBarHidden(true, animated: true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let tabBarController = self.tabBarController as? TabBarController {
            tabBarController.setCustomTabBarHidden(false, animated: true)
        }
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
        UserFirebaseService.shared.fetchTeacherStudentList(teacherID: userID ?? "") { [weak self] result in
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
        var fetchedStudents: [Student] = []
        
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
        cell.textLabel?.text = student.fullName
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        cell.addGestureRecognizer(longPressGesture)
        
        return cell
    }
    
    @objc private func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            guard let indexPath = tableView.indexPathForRow(at: gestureRecognizer.location(in: tableView)) else { return }
            let student = students[indexPath.row]
            showBlockConfirmation(for: student, at: indexPath)
        }
    }
    
    private func showBlockConfirmation(for student: Student, at indexPath: IndexPath) {
        let alertController = UIAlertController(title: "封鎖或檢舉", message: "你確定要封鎖並檢舉這位學生嗎？", preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "確認", style: .destructive) { _ in
            guard let userID = self.userID else {
                print("錯誤: 無法取得當前使用者 ID")
                return
            }
            
            UserFirebaseService.shared.blockUser(blockID: student.id, isTeacher: false) { error in
                if let error = error {
                    print("封鎖用戶失敗: \(error.localizedDescription)")
                    return
                }
                
                UserFirebaseService.shared.removeStudentFromTeacherNotes(teacherID: userID, studentID: student.id) { error in
                    if let error = error {
                        print("從 Firebase 中刪除學生失敗: \(error.localizedDescription)")
                    } else {
                        print("成功從 Firebase 中刪除學生 \(student.id)")
                        
                        self.students.remove(at: indexPath.row)
                        self.tableView.deleteRows(at: [indexPath], with: .automatic)
                    }
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
}
