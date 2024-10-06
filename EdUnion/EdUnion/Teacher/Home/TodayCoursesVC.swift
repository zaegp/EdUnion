//
//  TodayCoursesVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/18.
//

import UIKit
import SwiftUI

struct Courses {
    var title: String
    var time: String
    var isCompleted: Bool
}

class TodayCoursesVC: UIViewController {
    
    let tableView = UITableView()
    private var viewModel = TodayCoursesViewModel()
    
    private let progressBarHostingController = UIHostingController(rootView: ProgressBarView(value: 0.0))
    let titleLabel = UILabel()
    let noCoursesLabel = UILabel()
    let stackView = UIStackView()
    var expandedIndexPath: IndexPath?
    let userID = UserSession.shared.currentUserID
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        setupNavigationBar()
        setupConstraints()
        setupViewModel()
    }

    private func createTableHeader() -> UIView {
        let headerView = UIView()
        headerView.backgroundColor = .myCell
        
        return headerView
    }
    
    private func configureUI() {
        view.backgroundColor = .myBackground
        progressBarHostingController.view.backgroundColor = .myBackground
        
        titleLabel.text = "Today's Courses"
        titleLabel.font = UIFont.systemFont(ofSize: 30, weight: .bold)
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)
        
        noCoursesLabel.text = "今日無課程"
        noCoursesLabel.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        noCoursesLabel.textAlignment = .center
        noCoursesLabel.isHidden = true // 預設隱藏
        view.addSubview(noCoursesLabel)
        
        addChild(progressBarHostingController)
        view.addSubview(progressBarHostingController.view)
        progressBarHostingController.didMove(toParent: self)
        
        tableView.layer.cornerRadius = 20
        tableView.layer.masksToBounds = true
        tableView.backgroundColor = .myCell
        tableView.separatorStyle = .none
        tableView.register(TodayCoursesCell.self, forCellReuseIdentifier: "Cell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = createTableHeader()
        tableView.tableHeaderView?.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 20)
        view.addSubview(tableView)
    }
    
    private func setupNavigationBar() {
        let iconButton = UIBarButtonItem(
            image: UIImage(systemName: "bell"),
            style: .plain,
            target: self,
            action: #selector(pushToConfirmVC)
        )
        iconButton.tintColor = .black
        navigationItem.rightBarButtonItem = iconButton
    }
    
    @objc private func pushToConfirmVC() {
        let confirmVC = ConfirmVC()
        navigationController?.pushViewController(confirmVC, animated: true)
    }
    
    private func setupConstraints() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        noCoursesLabel.translatesAutoresizingMaskIntoConstraints = false
        progressBarHostingController.view.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
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
    
    private func setupViewModel() {
        viewModel.updateUI = { [weak self] in
            DispatchQueue.main.async {
                if self?.viewModel.appointments.isEmpty == true {
                    // 無課程，顯示無課程標籤並隱藏進度條
//                    self?.progressBarHostingController.view.isHidden = true
                    self?.noCoursesLabel.isHidden = false
                    self?.tableView.isHidden = true
                } else {
                    // 有課程，顯示進度條並隱藏無課程標籤
//                    self?.progressBarHostingController.view.isHidden = false
                    self?.noCoursesLabel.isHidden = true
                    self?.tableView.isHidden = false
                    self?.progressBarHostingController.rootView.value = self?.viewModel.progressValue ?? 0.0
                }
                self?.tableView.reloadData()
            }
        }
        viewModel.fetchTodayAppointments()
    }
}
// MARK: - UITableViewDataSource
extension TodayCoursesVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return expandedIndexPath == indexPath ? 200 : 80
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.appointments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! TodayCoursesCell
        cell.backgroundColor = .myCell
        configureCell(cell, at: indexPath)
        
        return cell
    }
    
    private func configureCell(_ cell: TodayCoursesCell, at indexPath: IndexPath) {
        let appointment = viewModel.appointments[indexPath.row]
        
        // 先獲取學生名字
        viewModel.fetchStudentName(for: appointment) { [weak self] studentName in
            DispatchQueue.main.async {
                // 獲取備註
                self?.viewModel.fetchStudentNote(teacherID: appointment.teacherID, studentID: appointment.studentID)
                
                // 配置 cell
                cell.configureCell(
                    name: studentName,
                    times: appointment.times,
                    note: self?.viewModel.studentNote ?? "無備註",
                    isExpanded: self?.expandedIndexPath == indexPath
                )
                
                // 更新按鈕狀態
                self?.updateCellButtonState(cell, appointment: appointment)
            }
        }
        
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
            self?.viewModel.completeCourse(appointmentID: appointment.id ?? "", teacherID: appointment.teacherID)
            cell.confirmButton.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
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
        tableView.beginUpdates()
        tableView.reloadRows(at: indexPathsToReload, with: .fade)
        tableView.endUpdates()
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
}
