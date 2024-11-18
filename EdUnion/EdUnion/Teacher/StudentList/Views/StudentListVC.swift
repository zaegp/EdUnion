//
//  StudentListVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/23.
//

import UIKit

class StudentListVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private let tableView = UITableView()
    private let emptyStateLabel = UILabel()
    private var viewModel = StudentListViewModel()
    
    let userID = UserSession.shared.unwrappedUserID
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .myBackground
        navigationItem.title = "學生名單"
        
        setupTableView()
        setupEmptyStateLabel()
        bindViewModel()
        viewModel.fetchStudents(for: userID)
        enableSwipeToGoBack()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let tabBarController = self.tabBarController as? TabBarController {
            tabBarController.setCustomTabBarHidden(true, animated: true)
        }
    }
    
    private func bindViewModel() {
        viewModel.onDataUpdated = { [weak self] in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
                self?.updateEmptyState()
            }
        }
    }
    
    private func setupTableView() {
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
        emptyStateLabel.text = "還沒有學生，快去上課吧！"
        emptyStateLabel.textColor = .gray
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        emptyStateLabel.isHidden = true
        view.addSubview(emptyStateLabel)
        
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -80)
        ])
    }
    
    private func updateEmptyState() {
        emptyStateLabel.isHidden = !viewModel.students.isEmpty
        tableView.isHidden = viewModel.students.isEmpty
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.students.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "studentCell", for: indexPath) as? StudentCell else {
            return UITableViewCell()
        }
        cell.backgroundColor = .myBackground
        cell.selectionStyle = .none
        
        let student = viewModel.students[indexPath.row]
        
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
        
        NSLayoutConstraint.activate([
            notePopupView.topAnchor.constraint(equalTo: self.view.topAnchor),
            notePopupView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            notePopupView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            notePopupView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        ])
        
        let existingNote = viewModel.studentsNotes[student.id] ?? ""
        notePopupView.setExistingNoteText(existingNote)
        
        notePopupView.onSave = { [weak self, weak notePopupView] noteText in
            self?.viewModel.saveNoteText(noteText, for: student, teacherID: self?.userID ?? "") { result in
                switch result {
                case .success:
                    notePopupView?.removeFromSuperview()
                case .failure(let error):
                    print("保存備註失敗: \(error.localizedDescription)")
                }
            }
        }
        
        notePopupView.onCancel = {
            notePopupView.removeFromSuperview()
        }
    }
    
    private func showBlockConfirmation(for student: Student, at indexPath: IndexPath) {
        let alertController = UIAlertController(title: "封鎖並檢舉", message: "你確定要封鎖並檢舉這位學生嗎？", preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "確認", style: .destructive) { _ in
            
            self.viewModel.blockStudent(student, teacherID: self.userID) { result in
                switch result {
                case .success:
                    print("成功封鎖並移除學生")
                case .failure(let error):
                    print("封鎖學生失敗: \(error.localizedDescription)")
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
}
