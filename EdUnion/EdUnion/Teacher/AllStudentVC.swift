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
        return cell
    }
}
