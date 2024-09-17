//
//  ConfirmVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/16.
//

import UIKit
import FirebaseCore

class ConfirmVC: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var tableView: UITableView!
    var viewModel: ConfirmViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = ConfirmViewModel(teacherID: teacherID)
        viewModel.updateUI = { [weak self] in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
        
        setupTableView()
        viewModel.loadPendingAppointments()
    }
    
    // MARK: - TableView
    func setupTableView() {
        tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.register(ConfirmCell.self, forCellReuseIdentifier: "ConfirmCell")
        view.addSubview(tableView)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.appointments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ConfirmCell", for: indexPath) as! ConfirmCell
        let appointment = viewModel.appointments[indexPath.row]
        cell.titleLabel.text = appointment.studentID
        cell.timeLabel.text = appointment.date
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let appointment = viewModel.appointments[indexPath.row]
        print("1111111")
        print(appointment.id)
        let alert = UIAlertController(title: "確認預約", message: "確定接受或拒絕預約？", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "接受", style: .default, handler: { _ in
            self.viewModel.confirmAppointment(appointmentID: appointment.id ?? "")
        }))
        
        alert.addAction(UIAlertAction(title: "拒絕", style: .destructive, handler: { _ in
            self.viewModel.rejectAppointment(appointmentID: appointment.id ?? "")
        }))
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
}
