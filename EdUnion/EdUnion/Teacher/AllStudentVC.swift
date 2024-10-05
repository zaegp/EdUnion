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
    let userID = UserSession.shared.currentUserID
    
    var onBlockAction: (() -> Void)?
       var onAddNoteAction: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "學生名單"
        
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
    
    private func showMenu(for student: Student, at indexPath: IndexPath, from button: UIButton) {
        let blockAction = UIAction(title: "封鎖", image: UIImage(systemName: "hand.raised.fill"), attributes: .destructive) { [weak self] _ in
            self?.showBlockConfirmation(for: student, at: indexPath)
        }
        
        let addNoteAction = UIAction(title: "新增備註", image: UIImage(systemName: "pencil")) { [weak self] _ in
            self?.showAddNoteView(for: student)
        }
        
        let menu = UIMenu(title: "", children: [blockAction, addNoteAction])
        
        button.menu = menu
        button.showsMenuAsPrimaryAction = true
    }
    
    private func showAddNoteView(for student: Student) {
        let notePopupView = NotePopupView()
        notePopupView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(notePopupView)
        
        // 設置約束
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
                self?.studentsNotes[student.id] = noteText
            case .failure(let error):
                print("保存備註失敗: \(error.localizedDescription)")
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
        
        let student = students[indexPath.row]
        
        // 設置菜單動作的回調
        cell.onBlockAction = { [weak self] in
            self?.showBlockConfirmation(for: student, at: indexPath)
        }
        
        cell.onAddNoteAction = { [weak self] in
            self?.showAddNoteView(for: student)
        }
        
        cell.configure(with: student)
        
        return cell
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
