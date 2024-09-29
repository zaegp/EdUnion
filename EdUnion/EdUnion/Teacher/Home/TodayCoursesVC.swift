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
    let userID = UserSession.shared.currentUserID
    
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
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 60),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            progressBarHostingController.view.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 50),
            progressBarHostingController.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressBarHostingController.view.widthAnchor.constraint(equalToConstant: 150),
            progressBarHostingController.view.heightAnchor.constraint(equalToConstant: 150),
            
            tableView.topAnchor.constraint(equalTo: progressBarHostingController.view.bottomAnchor, constant: 50),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

// MARK: - UITableViewDataSource
extension TodayCoursesVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if expandedIndexPath == indexPath {
            return 200
        }
        return 80    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.appointments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! TodayCoursesCell
        let appointment = viewModel.appointments[indexPath.row]
        viewModel.fetchStudentNote(teacherID: userID ?? "", studentID: appointment.studentID)
        
        viewModel.fetchStudentName(for: appointment) { studentName in
            DispatchQueue.main.async {
                cell.configureCell(name: studentName, times: appointment.times, note: self.viewModel.studentNote, isExpanded: self.expandedIndexPath == indexPath)
                // 檢查課程是否已完成並設置 UI
                if appointment.status == "completed" {
                    cell.confirmButton.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
                } else {
                    cell.confirmButton.setImage(UIImage(systemName: "circle"), for: .normal)
                }
            }
        }
        
        cell.confirmCompletion = { [weak self] in
                if appointment.status == "completed" {
                    return
                }
                
                let alert = UIAlertController(title: "完成課程", message: "確定要完成課程嗎?", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "確定", style: .default, handler: { _ in
                    self?.viewModel.completeCourse(appointmentID: appointment.id ?? "", teacherID: appointment.teacherID)
                    cell.confirmButton.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
                }))
                self?.present(alert, animated: true, completion: nil)
            }
        
        return cell
    }
    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        tableView.deselectRow(at: indexPath, animated: true)
//        
//        let previousExpandedIndexPath = expandedIndexPath
//        
//        if expandedIndexPath == indexPath {
//            expandedIndexPath = nil
//        } else {
//            expandedIndexPath = indexPath
//        }
//        
//        UIView.animate(withDuration: 0.3, animations: {
//                tableView.beginUpdates()
//                if let previousIndexPath = previousExpandedIndexPath {
//                    tableView.reloadRows(at: [previousIndexPath], with: .automatic)
//                }
//                tableView.reloadRows(at: [indexPath], with: .automatic)
//                tableView.endUpdates()
//                tableView.layoutIfNeeded() // 強制更新佈局，確保動畫平滑
//            })
//    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        var indexPathsToReload = [indexPath]
        
        if let expandedIndexPath = expandedIndexPath, expandedIndexPath != indexPath {
            indexPathsToReload.append(expandedIndexPath)
        }
        
        if expandedIndexPath == indexPath {
            self.expandedIndexPath = nil
        } else {
            self.expandedIndexPath = indexPath
        }

        tableView.beginUpdates()
        tableView.reloadRows(at: indexPathsToReload, with: UITableView.RowAnimation.fade) 
        tableView.endUpdates()
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
