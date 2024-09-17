//
//  ConfirmVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/16.
//

import UIKit
import FirebaseCore

class ConfirmVC: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var appointments: [Appointment] = []
    var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadPendingAppointments()
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
        return appointments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ConfirmCell", for: indexPath) as! ConfirmCell
            let appointment = appointments[indexPath.row]
        cell.titleLabel.text = appointment.studentID
        cell.timeLabel.text = appointment.date
            return cell
        }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let appointment = appointments[indexPath.row]
        let alert = UIAlertController(title: "確認預約", message: "確定接受或拒絕預約？", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "接受", style: .default, handler: { _ in
            self.confirmAppointment(appointmentID: appointment.id ?? "")
        }))
        
        alert.addAction(UIAlertAction(title: "拒絕", style: .destructive, handler: { _ in
            self.rejectAppointment(appointmentID: appointment.id ?? "")
        }))
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Firebase 加載待確認的預約
    private func loadPendingAppointments() {
        FirebaseService.shared.fetchPendingAppointments(forTeacherID: teacherID) { result in
            switch result {
            case .success(let fetchedAppointments):
                self.appointments = fetchedAppointments
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            case .failure(let error):
                print("加載預約失敗：\(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - 預約狀態處理
    private func confirmAppointment(appointmentID: String) {
        FirebaseService.shared.updateAppointmentStatus(appointmentID: appointmentID, status: "confirmed") { result in
            switch result {
            case .success:
                print("預約已確認")
                self.loadPendingAppointments()
            case .failure(let error):
                print("更新預約狀態失敗: \(error.localizedDescription)")
            }
        }
    }

    private func rejectAppointment(appointmentID: String) {
        FirebaseService.shared.updateAppointmentStatus(appointmentID: appointmentID, status: "rejected") { result in
            switch result {
            case .success:
                print("預約已拒絕")
                self.loadPendingAppointments()
            case .failure(let error):
                print("更新預約狀態失敗: \(error.localizedDescription)")
            }
        }
    }
}
