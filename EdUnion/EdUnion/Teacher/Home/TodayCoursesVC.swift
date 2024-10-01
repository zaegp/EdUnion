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
    
    private let progressBarHostingController = UIHostingController(rootView: ProgressContentView())
    let titleLabel = UILabel()
    let bellButton = UIButton()
    var expandedIndexPath: IndexPath?
    let userID = UserSession.shared.currentUserID
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        setupConstraints()
        setupViewModel()
    }
    
    private func createTableHeader() -> UIView {
        let headerView = UIView()
        headerView.backgroundColor = UIColor(red: 0.10, green: 0.10, blue: 0.12, alpha: 1.00)
        
        return headerView
    }
    
    private func configureUI() {
        view.backgroundColor = .systemBackground
        
        titleLabel.text = "Today's Courses"
        titleLabel.font = UIFont.systemFont(ofSize: 30, weight: .bold)
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)
        
        bellButton.setImage(UIImage(systemName: "bell"), for: .normal)
        bellButton.tintColor = .black
        bellButton.addTarget(self, action: #selector(pushToConfirmVC), for: .touchUpInside)
        view.addSubview(bellButton)
        
        view.bringSubviewToFront(bellButton)
        
        addChild(progressBarHostingController)
        view.addSubview(progressBarHostingController.view)
        progressBarHostingController.didMove(toParent: self)
        
        tableView.layer.cornerRadius = 20
        tableView.layer.masksToBounds = true
        tableView.backgroundColor = UIColor(red: 0.10, green: 0.10, blue: 0.12, alpha: 1.00)
        tableView.separatorStyle = .none
        tableView.register(TodayCoursesCell.self, forCellReuseIdentifier: "Cell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = createTableHeader()
        view.addSubview(tableView)
    }

    
    @objc private func pushToConfirmVC() {
        let confirmVC = ConfirmVC()
        navigationController?.pushViewController(confirmVC, animated: true)
    }
    
    private func setupConstraints() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        bellButton.translatesAutoresizingMaskIntoConstraints = false
        progressBarHostingController.view.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            bellButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            bellButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            bellButton.widthAnchor.constraint(equalToConstant: 30),
            bellButton.heightAnchor.constraint(equalToConstant: 30),
            
            progressBarHostingController.view.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            progressBarHostingController.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressBarHostingController.view.widthAnchor.constraint(equalToConstant: 150),
            progressBarHostingController.view.heightAnchor.constraint(equalToConstant: 150),
            
            tableView.topAnchor.constraint(equalTo: progressBarHostingController.view.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupViewModel() {
        viewModel.updateUI = { [weak self] in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
//                self?.progressBarHostingController.rootView.value = self?.viewModel.progressValue ?? 0.0
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
        configureCell(cell, at: indexPath)
        return cell
    }
    
    private func configureCell(_ cell: TodayCoursesCell, at indexPath: IndexPath) {
//        cell.backgroundColor = UIColor(red: 0.10, green: 0.10, blue: 0.12, alpha: 1.00)
        cell.backgroundColor = .white
        let appointment = viewModel.appointments[indexPath.row]
        
        viewModel.fetchStudentName(for: appointment) { [weak self] studentName in
            DispatchQueue.main.async {
                cell.configureCell(
                    name: studentName,
                    times: appointment.times,
                    note: self?.viewModel.studentNote ?? "",
                    isExpanded: self?.expandedIndexPath == indexPath
                )
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
