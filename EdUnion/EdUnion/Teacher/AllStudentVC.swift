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
    private var studentsNotes: [String: String] = [:]
    private let emptyStateLabel = UILabel() // 用於顯示空狀態的標籤
    let userID = UserSession.shared.currentUserID
    
    var onBlockAction: (() -> Void)?
    var onAddNoteAction: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "學生名單"
        
        setupTableView()
        setupEmptyStateLabel() // 設置空狀態標籤
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
        tableView.backgroundColor = .myBackground
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(StudentCell.self, forCellReuseIdentifier: "studentCell")
        tableView.separatorStyle = .none
        view.addSubview(tableView)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupEmptyStateLabel() {
        emptyStateLabel.text = "No students available."
        emptyStateLabel.textColor = .myGray
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        emptyStateLabel.isHidden = true // 初始時隱藏
        view.addSubview(emptyStateLabel)
        
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -80) // 上移 80 點
        ])
    }
    
    func fetchStudents() {
        UserFirebaseService.shared.fetchTeacherStudentList(teacherID: userID ?? "") { [weak self] result in
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
        updateEmptyState() // 更新空狀態標籤的顯示
    }
    
    private func updateEmptyState() {
        emptyStateLabel.isHidden = !students.isEmpty
        tableView.isHidden = students.isEmpty
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return students.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "studentCell", for: indexPath) as? StudentCell else {
            return UITableViewCell()
        }
        cell.backgroundColor = .myBackground
        cell.selectionStyle = .none
        
        let student = students[indexPath.row]
        
        cell.onBlockAction = { [weak self] in
            self?.showBlockConfirmation(for: student, at: indexPath)
        }
        
        cell.onAddNoteAction = { [weak self] in
            self?.showAddNoteView(for: student)
        }
        
        cell.configure(with: student)
        
        return cell
    }
    
    private func showAddNoteView(for student: Student) {
        let notePopupView = NotePopupView()
        notePopupView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(notePopupView)
        
        // 設定約束
        NSLayoutConstraint.activate([
            notePopupView.topAnchor.constraint(equalTo: self.view.topAnchor),
            notePopupView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            notePopupView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            notePopupView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        ])
        
        // 使用 studentsNotes 來取得現有備註
        let existingNote = studentsNotes[student.id] ?? ""
        notePopupView.setExistingNoteText(existingNote)
        
        // 處理保存動作
        notePopupView.onSave = { [weak self, weak notePopupView] noteText in
            self?.saveNoteText(noteText, for: student)
            notePopupView?.removeFromSuperview()
        }
        
        // 處理取消動作
        notePopupView.onCancel = { [weak notePopupView] in
            notePopupView?.removeFromSuperview()
        }
    }
    
    private func saveNoteText(_ noteText: String, for student: Student) {
        guard let teacherID = userID else { return }
        
        UserFirebaseService.shared.updateStudentNotes(forTeacher: teacherID, studentID: student.id, note: noteText) { [weak self] result in
            switch result {
            case .success(_):
                print("備註已成功保存。")
                // 更新本地的 studentsNotes 字典
                self?.studentsNotes[student.id] = noteText
                // 更新 UI
                self?.updateUI()
            case .failure(let error):
                print("保存備註失敗: \(error.localizedDescription)")
            }
        }
    }
    
    private func showBlockConfirmation(for student: Student, at indexPath: IndexPath) {
        let alertController = UIAlertController(title: "封鎖並檢舉", message: "你確定要封鎖並檢舉這位學生嗎？", preferredStyle: .alert)
        
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
                        self.updateUI()
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
