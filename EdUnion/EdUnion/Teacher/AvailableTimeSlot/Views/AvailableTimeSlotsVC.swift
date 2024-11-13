//
//  AvailableTimeSlotsVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/13.
//

import UIKit
import SwiftUI

class AvailableTimeSlotsVC: UIViewController {
    private let tableView = UITableView()
    
    private let teacherID = UserSession.shared.unwrappedUserID
    private var viewModel: AvailableTimeSlotsViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.viewModel = AvailableTimeSlotsViewModel()
        
        title = "可選時段"
        view.backgroundColor = .myBackground
        
        setupNavigationBar()
        enableSwipeToGoBack()
        setupTableView()
        setupAddButton()
        
        bindViewModel()
        viewModel.loadTimeSlots()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let tabBarController = self.tabBarController as? TabBarController {
            tabBarController.setCustomTabBarHidden(true, animated: true)
        }
    }
    
    func setupNavigationBar() {
        let iconImage = UIImage(systemName: "calendar")
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: iconImage, style: .plain, target: self, action: #selector(pushToCalendarVC))
        navigationItem.rightBarButtonItem?.tintColor = .mainOrange
    }
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(AvailableTimeSlotsCell.self, forCellReuseIdentifier: "AvailableTimeSlotsCell")
        
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = .clear
        tableView.rowHeight = 60
        tableView.layer.cornerRadius = 10
        tableView.clipsToBounds = true
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100)
        ])
    }
    
    func setupAddButton() {
        let addButton = UIButton(type: .system)
        addButton.setTitle("新增顏色", for: .normal)
        addButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        addButton.setTitleColor(.white, for: .normal)
        addButton.backgroundColor = .mainOrange
        addButton.layer.cornerRadius = 10
        addButton.addTarget(self, action: #selector(showColorTimePickerModal), for: .touchUpInside)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addButton)
        
        NSLayoutConstraint.activate([
            addButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            addButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    func bindViewModel() {
        viewModel.onTimeSlotsChanged = { [weak self] in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
    }
    
    @objc func showColorTimePickerModal() {
        let modalVC = ColorTimePickerVC()
        modalVC.existingTimeRanges = viewModel.timeSlots.flatMap { $0.timeRanges }
        modalVC.existingColors = viewModel.existingColors()
        modalVC.onTimeSlotSelected = { [weak self] newTimeSlot in
            self?.viewModel.addTimeSlot(newTimeSlot)
        }
        modalVC.modalPresentationStyle = .formSheet
        present(modalVC, animated: true, completion: nil)
    }
    
    func showEditTimeSlotModal(for timeSlot: AvailableTimeSlot, at index: Int) {
        let modalVC = ColorTimePickerVC()
        modalVC.existingTimeSlots = viewModel.timeSlots
        modalVC.editingTimeSlot = timeSlot
        modalVC.onTimeSlotEdited = { [weak self] editedTimeSlot in
            self?.viewModel.updateTimeSlot(at: index, with: editedTimeSlot)
        }
        modalVC.modalPresentationStyle = .formSheet
        present(modalVC, animated: true, completion: nil)
    }
    
    @objc func pushToCalendarVC() {
        let calendarView = ColorPickerCalendarView()
        let hostingController = UIHostingController(rootView: calendarView)
        hostingController.modalPresentationStyle = .pageSheet
        hostingController.modalTransitionStyle = .coverVertical
        present(hostingController, animated: true, completion: nil)
    }
}

extension AvailableTimeSlotsVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.timeSlots.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: AvailableTimeSlotsCell = tableView.dequeueReusableCell(
            withIdentifier: "AvailableTimeSlotsCell",
            for: indexPath
        )
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        
        let timeSlot = viewModel.timeSlots[indexPath.row]
        cell.configure(with: timeSlot)
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
            cell.contentView.layer.masksToBounds = true
            cell.contentView.layer.cornerRadius = 12
            
            let cellMargins = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
            cell.frame = cell.frame.inset(by: cellMargins)
        }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            viewModel.deleteTimeSlot(at: indexPath.row)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let timeSlot = viewModel.timeSlots[indexPath.row]
        showEditTimeSlotModal(for: timeSlot, at: indexPath.row)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
