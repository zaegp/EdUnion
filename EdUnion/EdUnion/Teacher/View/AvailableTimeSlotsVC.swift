//
//  AvailableTimeSlotsVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/13.
//

import UIKit

class AvailableTimeSlotsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    struct TimeSlot {
        var color: UIColor
        var timeRanges: [String]
    }

    private var timeSlots: [TimeSlot] = []
    private let tableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Time Slots"
        view.backgroundColor = .systemGroupedBackground
        
        setupTableView()
        setupAddButton()
    }

    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "TimeSlotCell")
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = .clear
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
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
        let modalVC = TimePickerViewController()
        modalVC.existingTimeRanges = timeSlots.flatMap { $0.timeRanges }
        modalVC.onTimeSlotSelected = { [weak self] timeRanges, color in
            let newSlot = TimeSlot(color: color, timeRanges: timeRanges)
            self?.timeSlots.append(newSlot)
            self?.tableView.reloadData()
        }
        modalVC.modalPresentationStyle = .pageSheet
        if let sheet = modalVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
        }
        present(modalVC, animated: true, completion: nil)
    }

    // MARK: - UITableViewDelegate, UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return timeSlots.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TimeSlotCell", for: indexPath)
        let timeSlot = timeSlots[indexPath.row]
        cell.textLabel?.text = timeSlot.timeRanges.joined(separator: ", ")
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        cell.backgroundColor = timeSlot.color.withAlphaComponent(0.2)
        cell.textLabel?.textColor = .label
        cell.layer.cornerRadius = 10
        cell.clipsToBounds = true
        return cell
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            timeSlots.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
}
