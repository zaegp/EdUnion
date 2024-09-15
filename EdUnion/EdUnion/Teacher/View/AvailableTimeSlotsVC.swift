//
//  AvailableTimeSlotsVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/13.
//

import UIKit

class AvailableTimeSlotsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private var viewModel: AvailableTimeSlotsViewModel!
    private let tableView = UITableView()
    private let teacherID: String  // You should set this when initializing the VC
    
    init(teacherID: String) {
        self.teacherID = teacherID
        super.init(nibName: nil, bundle: nil)
        self.viewModel = AvailableTimeSlotsViewModel(teacherID: teacherID)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Available Time Slots"
        view.backgroundColor = .systemGroupedBackground
        
        setupTableView()
        setupAddButton()
        bindViewModel()
        viewModel.loadTimeSlots()
    }
    
    func bindViewModel() {
        viewModel.onTimeSlotsChanged = { [weak self] in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
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
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100)
        ])
    }
    
    func setupAddButton() {
        let addButton = UIButton(type: .system)
        addButton.setTitle("Add Time Slot", for: .normal)
        addButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        addButton.setTitleColor(.white, for: .normal)
        addButton.backgroundColor = .systemBlue
        addButton.layer.cornerRadius = 10
        addButton.addTarget(self, action: #selector(showTimePickerModal), for: .touchUpInside)
        
        view.addSubview(addButton)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            addButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            addButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc func showTimePickerModal() {
        let modalVC = ColorTimePickerVC()
        modalVC.existingTimeRanges = viewModel.timeSlots.flatMap { $0.timeRanges }
        modalVC.existingColors = viewModel.existingColors() // 传递已有的颜色列表
        modalVC.onTimeSlotSelected = { [weak self] newTimeSlot in
            self?.viewModel.addTimeSlot(newTimeSlot)
        }
        modalVC.modalPresentationStyle = .fullScreen
        present(modalVC, animated: true, completion: nil)
    }


    
    // MARK: - UITableViewDelegate, UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.timeSlots.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // Use your custom cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "AvailableTimeSlotsCell", for: indexPath) as! AvailableTimeSlotsCell
        let timeSlot = viewModel.timeSlots[indexPath.row]
        cell.configure(with: timeSlot)
        return cell
    }
    
    // Handle deletion
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,     forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            viewModel.deleteTimeSlot(at: indexPath.row)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let timeSlot = viewModel.timeSlots[indexPath.row]
        showEditTimeSlotModal(for: timeSlot, at: indexPath.row)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func showEditTimeSlotModal(for timeSlot: AvailableTimeSlot, at index: Int) {
        let modalVC = ColorTimePickerVC()
        modalVC.existingTimeSlots = viewModel.timeSlots // 传递所有已有的时间段
        modalVC.editingTimeSlot = timeSlot // 传递要编辑的时间段
        modalVC.onTimeSlotEdited = { [weak self] editedTimeSlot in
            self?.viewModel.updateTimeSlot(at: index, with: editedTimeSlot)
        }
        modalVC.modalPresentationStyle = .fullScreen
        present(modalVC, animated: true, completion: nil)
    }
}
