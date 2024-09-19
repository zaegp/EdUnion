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
    var expandedIndexPath: IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.updateUI = { [weak self] in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
                self?.progressBarHostingController.rootView.value = self?.viewModel.progressValue ?? 0.0

            }
        }
        
        viewModel.fetchTodayAppointments()
        
        view.backgroundColor = .systemBackground
        tableView.separatorStyle = .none
        tableView.register(TodayCoursesCell.self, forCellReuseIdentifier: "Cell")
        
        tableView.delegate = self
        tableView.dataSource = self
        
        titleLabel.text = "Today's Courses"
        titleLabel.font = UIFont.systemFont(ofSize: 30, weight: .bold)
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)
        
        addChild(progressBarHostingController)
        view.addSubview(progressBarHostingController.view)
        progressBarHostingController.didMove(toParent: self)
        
        
        view.addSubview(tableView)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        progressBarHostingController.view.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 80),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            progressBarHostingController.view.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 50),
            progressBarHostingController.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressBarHostingController.view.widthAnchor.constraint(equalToConstant: 200),
            progressBarHostingController.view.heightAnchor.constraint(equalToConstant: 200),
            
            tableView.topAnchor.constraint(equalTo: progressBarHostingController.view.bottomAnchor, constant: 100),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)  // 填滿剩餘空間
        ])
    }
}

// MARK: - UITableViewDataSource
extension TodayCoursesVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if expandedIndexPath == indexPath {
            return 200 // Expanded height
        }
        return 80    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.appointments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! TodayCoursesCell
        let appointment = viewModel.appointments[indexPath.row]
        
        UserFirebaseService.shared.fetchStudentName(by: appointment.studentID) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let studentName):
                    cell.titleLabel.text = studentName ?? "Unknown Student" // 如果 studentName 是 nil，顯示 "Unknown Student"
                case .failure:
                    cell.titleLabel.text = "Unknown Student"
                }
            }
        }
        
        if let firstTime = appointment.times.first, let lastTime = appointment.times.last {
            if appointment.times.count > 1 {
                // 如果有多個時間，顯示最早和最晚的時間
                cell.timeLabel.text = "Time: \(firstTime) - \(lastTime)"
            } else {
                // 如果只有一個時間，顯示單個時間
//                cell.timeLabel.text = firstTime
            }
        }
        
        // 設置完成確認的邏輯
        cell.confirmCompletion = { [weak self] in
            let alert = UIAlertController(title: "Confirm Completion", message: "Do you want to mark this course as completed?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { _ in
                cell.confirmButton.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
                // 更新課程狀態
                self?.viewModel.completeCourse(appointmentID: appointment.id ?? "", teacherID: appointment.teacherID)
            }))
            self?.present(alert, animated: true, completion: nil)
        }
        
        return cell
    }
    
    //    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    //        let datePickerVC = DatePickerViewController()
    //
    //        datePickerVC.modalPresentationStyle = .pageSheet
    //        if let sheet = datePickerVC.sheetPresentationController {
    //            sheet.detents = [.medium()]
    //        }
    //
    //        datePickerVC.saveHandler = { [weak self] newDate in
    //            let formatter = DateFormatter()
    //            formatter.dateFormat = "hh:mm a"
    //            let newTime = formatter.string(from: newDate)
    //            self?.sampleCourses[indexPath.row].time = newTime
    //            tableView.reloadRows(at: [indexPath], with: .automatic)
    //        }
    //
    //        present(datePickerVC, animated: true, completion: nil)
    //    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if expandedIndexPath == indexPath {
            // Collapse if it's already expanded
            expandedIndexPath = nil
        } else {
            // Expand the selected cell
            expandedIndexPath = indexPath
        }
        
        UIView.animate(withDuration: 0.3) {
            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }
    
    //    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    //        if editingStyle == .delete {
    //            sampleCourses.remove(at: indexPath.row)
    //
    //            tableView.deleteRows(at: [indexPath], with: .automatic)
    //        }
    //    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
}


