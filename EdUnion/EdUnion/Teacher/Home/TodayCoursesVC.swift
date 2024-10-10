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

class BadgeButton: UIButton {
    private let badgeLabel = UILabel()
    
    var badgeNumber: Int = 0 {
        didSet {
            updateBadge()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupBadge()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupBadge()
    }
    
    private func setupBadge() {
        badgeLabel.backgroundColor = .mainOrange
        badgeLabel.textColor = .white
        badgeLabel.font = UIFont.systemFont(ofSize: 12)
        badgeLabel.textAlignment = .center
        badgeLabel.layer.cornerRadius = 10
        badgeLabel.clipsToBounds = true
        badgeLabel.isHidden = true
        addSubview(badgeLabel)
        
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            badgeLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: -5),
            badgeLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 5),
            badgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 20),
            badgeLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    func setBadge(number: Int) {
        badgeNumber = number
    }
    
    private func updateBadge() {
        if badgeNumber > 0 {
            badgeLabel.text = "\(badgeNumber)"
            badgeLabel.isHidden = false
        } else {
            badgeLabel.isHidden = true
        }
    }
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
    
    let bellButton = BadgeButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        setupNavigationBar()
        setupConstraints()
        setupViewModel()
        
        viewModel.listenToPendingAppointments()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let tabBarController = self.tabBarController as? TabBarController {
            tabBarController.setCustomTabBarHidden(false, animated: true)
        }
        
        viewModel.fetchTodayAppointments()
        updateBellBadge()
    }
    
    @objc func updateBellBadge() {
        let pendingCount = viewModel.getPendingAppointmentsCount()
        bellButton.setBadge(number: pendingCount)
        print("Bell badge updated: \(pendingCount)")
    }

    private func createTableHeader() -> UIView {
        let headerView = UIView()
        headerView.backgroundColor = .myCell
        
        return headerView
    }
    
    private func configureUI() {
        noCoursesLabel.isHidden = true
        view.backgroundColor = .myBackground
        progressBarHostingController.view.backgroundColor = .myBackground
        
        titleLabel.text = "Today's Courses"
        titleLabel.font = UIFont.systemFont(ofSize: 30, weight: .bold)
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)
        
        noCoursesLabel.text = "今日無課程"
        noCoursesLabel.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        noCoursesLabel.textAlignment = .center
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
            // 配置 bell 按鈕
            bellButton.setImage(UIImage(systemName: "bell.fill"), for: .normal)
            bellButton.tintColor = .label
            bellButton.addTarget(self, action: #selector(pushToConfirmVC), for: .touchUpInside)
            
            let bellBarButtonItem = UIBarButtonItem(customView: bellButton)
            navigationItem.rightBarButtonItem = bellBarButtonItem
        }
    
    @objc private func pushToConfirmVC() {
            let pendingAppointments = viewModel.pendingAppointments
            let confirmVC = ConfirmVC(appointments: pendingAppointments)
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
                    self?.noCoursesLabel.isHidden = false
                    self?.tableView.backgroundView = self?.noCoursesLabel
                } else {
                    self?.noCoursesLabel.isHidden = true
                    self?.tableView.backgroundView = nil
                    self?.progressBarHostingController.rootView.value = self?.viewModel.progressValue ?? 0.0
                }
                self?.tableView.reloadData()
                
                // 直接在這裡更新鐘形徽章
                self?.updateBellBadge()
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
        
        viewModel.fetchStudentName(for: appointment) { [weak self] studentName in
            DispatchQueue.main.async {
                self?.viewModel.fetchStudentNote(teacherID: self?.userID ?? "", studentID: appointment.studentID)
                
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
        
        // 只更新需要的行，避免整個表格刷新
        tableView.reloadRows(at: indexPathsToReload, with: .fade)
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
}
