//
//  TodayCoursesVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/18.
//

import UIKit
import SwiftUI
import Combine

struct Courses {
    var title: String
    var time: String
    var isCompleted: Bool
}

class TodayCoursesVC: UIViewController {
    
    private let tableView = UITableView()
    private var viewModel = TodayCoursesViewModel()
    private let progressBarHostingController = UIHostingController(rootView: ProgressBarView(value: 0.0))
    private let titleLabel = UILabel()
    private let noCoursesLabel = UILabel()
    private let stackView = UIStackView()
    private var expandedIndexPath: IndexPath?
    private let userID = UserSession.shared.currentUserID
    private let bellButton = BadgeButton(type: .system)
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        setupNavigationBar()
        setupConstraints()
        setupViewModel()
        addTableViewGesture()
        
        bindViewModel()
        
        tableView.reloadData()
        viewModel.listenToPendingAppointments()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupTabBar()
        loadingIndicator.startAnimating()
        viewModel.fetchTodayAppointments { [weak self] in
            self?.loadingIndicator.stopAnimating()
        }
        updateBellBadge()
    }
    
    // MARK: - UI Setup
    private func configureUI() {
        view.backgroundColor = .myBackground
        noCoursesLabel.isHidden = true
        configureTitleLabel()
        configureNoCoursesLabel()
        configureProgressBar()
        configureTableView()
    }
    
    private func configureTitleLabel() {
        titleLabel.text = "Today's Courses"
        titleLabel.font = UIFont.systemFont(ofSize: 30, weight: .bold)
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)
    }
    
    private func configureNoCoursesLabel() {
        noCoursesLabel.text = "今日無課程"
        noCoursesLabel.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        noCoursesLabel.textAlignment = .center
        view.addSubview(noCoursesLabel)
    }
    
    private func configureProgressBar() {
        addChild(progressBarHostingController)
        progressBarHostingController.view.backgroundColor = .myBackground
        view.addSubview(progressBarHostingController.view)
        progressBarHostingController.didMove(toParent: self)
    }
    
    private func configureTableView() {
        tableView.layer.cornerRadius = 20
        tableView.backgroundColor = .myCell
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(TodayCoursesCell.self, forCellReuseIdentifier: "Cell")
        tableView.tableHeaderView = createTableHeader()
        view.addSubview(tableView)
    }
    
    private func setupNavigationBar() {
        bellButton.setImage(UIImage(systemName: "bell.fill"), for: .normal)
        bellButton.tintColor = .label
        bellButton.addTarget(self, action: #selector(pushToConfirmVC), for: .touchUpInside)
        
        let bellBarButtonItem = UIBarButtonItem(customView: bellButton)
        navigationItem.rightBarButtonItem = bellBarButtonItem
    }
    
    private func setupTabBar() {
        (tabBarController as? TabBarController)?.setCustomTabBarHidden(false, animated: true)
    }
    
    private func setupConstraints() {
        [titleLabel, noCoursesLabel, progressBarHostingController.view, tableView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 60),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            progressBarHostingController.view.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 50),
            progressBarHostingController.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressBarHostingController.view.widthAnchor.constraint(equalToConstant: 150),
            progressBarHostingController.view.heightAnchor.constraint(equalToConstant: 150),
            
            noCoursesLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noCoursesLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -300),
            
            tableView.topAnchor.constraint(equalTo: progressBarHostingController.view.bottomAnchor, constant: 50),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - ViewModel Binding
    private func setupViewModel() {
        viewModel.updateUI = { [weak self] in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
                self?.updateBellBadge()
            }
        }
    }
    
    private func bindViewModel() {
        viewModel.$pendingAppointmentsCount
            .sink { [weak self] count in
                self?.bellButton.setBadge(number: count)
            }
            .store(in: &cancellables)
        
        viewModel.$appointments
            .sink { [weak self] appointments in
                self?.noCoursesLabel.isHidden = !appointments.isEmpty
                self?.tableView.backgroundView = appointments.isEmpty ? self?.noCoursesLabel : nil
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Table Header
    private func createTableHeader() -> UIView {
        let headerView = UIView()
        headerView.backgroundColor = .myCell
        
        headerView.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 20)
        
        return headerView
    }
    
    // MARK: - TableView Gesture
    private func addTableViewGesture() {
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        tableView.addGestureRecognizer(longPressGesture)
    }
    
    // MARK: - Bell Badge Update
    @objc func updateBellBadge() {
        let pendingCount = viewModel.getPendingAppointmentsCount()
        bellButton.setBadge(number: pendingCount)
        print("Bell badge updated: \(pendingCount)")
    }
    
    // MARK: - Actions
    @objc private func pushToConfirmVC() {
        let pendingAppointments = viewModel.pendingAppointments
        let confirmVC = ConfirmVC(appointments: pendingAppointments)
        navigationController?.pushViewController(confirmVC, animated: true)
    }
    
    @objc private func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let touchPoint = gestureRecognizer.location(in: self.tableView)
            
            if let indexPath = tableView.indexPathForRow(at: touchPoint) {
                let appointment = viewModel.appointments[indexPath.row]
                
                guard let studentName = viewModel.studentNames[appointment.studentID] else {
                    print("找不到對應的學生姓名")
                    return
                }
                
                let student = Student.self
                
                showAddNoteView(for: appointment.studentID)
            }
        }
    }
    
    private func showAddNoteView(for studentID: String) {
        let notePopupView = NotePopupView()
        setupNotePopupViewConstraints(notePopupView)
        
        notePopupView.setExistingNoteText(viewModel.studentNotes[studentID] ?? "")
        
        notePopupView.onSave = { [weak self, weak notePopupView] noteText in
            self?.viewModel.saveNoteText(noteText, for: studentID, teacherID: self?.userID ?? "") { result in
                if case .success = result {
                    notePopupView?.removeFromSuperview()
                    self?.reloadRowForStudent(studentID)
                }
            }
        }
        
        notePopupView.onCancel = {
            notePopupView.removeFromSuperview()
        }
    }
    
    private func setupNotePopupViewConstraints(_ notePopupView: NotePopupView) {
        view.addSubview(notePopupView)
        notePopupView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            notePopupView.topAnchor.constraint(equalTo: view.topAnchor),
            notePopupView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            notePopupView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            notePopupView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func reloadRowForStudent(_ studentID: String) {
        if let indexPath = viewModel.appointments.firstIndex(where: { $0.studentID == studentID }) {
            tableView.reloadRows(at: [IndexPath(row: indexPath, section: 0)], with: .automatic)
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension TodayCoursesVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return expandedIndexPath == indexPath ? 200 : 80
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.appointments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: TodayCoursesCell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.backgroundColor = .myCell
        configureCell(cell, at: indexPath)
        
        return cell
    }
    
    private func configureCell(_ cell: TodayCoursesCell, at indexPath: IndexPath) {
        let appointment = viewModel.appointments[indexPath.row]
        let studentID = appointment.studentID
        let studentName = viewModel.studentNames[studentID] ?? ""
        let studentNote = viewModel.studentNotes[studentID] ?? "沒有備註"
        
        cell.configureCell(
            name: studentName,
            times: appointment.times,
            note: studentNote,
            isExpanded: expandedIndexPath == indexPath
        )
        
        updateCellButtonState(cell, appointment: appointment)
        
        cell.confirmCompletion = { [weak self] in
            self?.handleCompletion(for: appointment, cell: cell)
        }
    }
    
    private func updateCellButtonState(_ cell: TodayCoursesCell, appointment: Appointment) {
        if appointment.status == "completed" {
            cell.confirmButton.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
        } else {
            cell.confirmButton.setImage(UIImage(systemName: "circle"), for: .normal)
        }
    }
    
    private func handleCompletion(for appointment: Appointment, cell: TodayCoursesCell) {
        guard appointment.status != "completed" else { return }
        
        let alert = UIAlertController(title: "完成課程", message: "確定要完成課程嗎?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "確定", style: .default, handler: { [weak self] _ in
            UIView.transition(with: cell.confirmButton, duration: 0.3, options: .transitionCrossDissolve, animations: {
                self?.viewModel.completeCourse(appointmentID: appointment.id ?? "", teacherID: appointment.teacherID)
                cell.confirmButton.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
            }, completion: nil)
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        var indexPathsToReload = [indexPath]
        if let expandedIndexPath = expandedIndexPath, expandedIndexPath != indexPath {
            indexPathsToReload.append(expandedIndexPath)
        }
        
        expandedIndexPath = (expandedIndexPath == indexPath) ? nil : indexPath
        
        tableView.reloadRows(at: indexPathsToReload, with: .fade)
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
}
