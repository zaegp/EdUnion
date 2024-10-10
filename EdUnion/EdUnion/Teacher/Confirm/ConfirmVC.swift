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
    
    init(appointments: [Appointment]) {
            self.viewModel = ConfirmViewModel(appointments: appointments, userID: UserSession.shared.currentUserID ?? "")
            super.init(nibName: nil, bundle: nil)
        }
    
    required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        setupViewModel()
        enableSwipeToGoBack()
        updateBackgroundView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.barTintColor = .myBackground
        navigationController?.navigationBar.shadowImage = UIImage()
        
        if let tabBarController = self.tabBarController as? TabBarController {
            tabBarController.setCustomTabBarHidden(true, animated: true)
        }
        
        updateBackgroundView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let tabBarController = self.tabBarController as? TabBarController {
            tabBarController.setCustomTabBarHidden(false, animated: true)
        }
    }
    
    private func setupViewModel() {
        viewModel.updateUI = { [weak self] in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
                self?.updateBackgroundView()
            }
        }
    }
    
    private func updateBackgroundView() {
        if viewModel.appointments.isEmpty {
            tableView.backgroundView = createEmptyStateView()
        } else {
            tableView.backgroundView = nil
        }
    }
    
    // MARK: - TableView
    func setupTableView() {
        tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .myBackground
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
        cell.backgroundColor = .myBackground
        let appointment = viewModel.appointments[indexPath.row]
        var isStudentExisting = false
        
        viewModel.updateStudentNotes(studentID: appointment.studentID, note: "") { result in
            switch result {
            case .success(let studentExists):
                if studentExists {
                    isStudentExisting = true
                }
            case .failure(let error):
                print("Failed to update note: \(error.localizedDescription)")
            }
        }
        
        viewModel.fetchStudentName(for: appointment) { studentName in
            DispatchQueue.main.async {
                cell.configureCell(date: appointment.date, title: studentName, times: appointment.times, isStudentExisting: isStudentExisting)
            }
        }
    
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let appointment = viewModel.appointments[indexPath.row]
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
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let appointment = viewModel.appointments[indexPath.row]
        
        let confirmAction = UIContextualAction(style: .normal, title: "接受") { action, view, completionHandler in
            self.viewModel.confirmAppointment(appointmentID: appointment.id ?? "")
            
            self.viewModel.appointments.remove(at: indexPath.row)
            
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
            feedbackGenerator.impactOccurred()
            
            completionHandler(true)
        }
        confirmAction.backgroundColor = .systemGreen
        
        return UISwipeActionsConfiguration(actions: [confirmAction])
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let appointment = viewModel.appointments[indexPath.row]
        
        let cancelAction = UIContextualAction(style: .destructive, title: "拒絕") { action, view, completionHandler in
            let alert = UIAlertController(title: "拒絕預約", message: "確定要拒絕預約嗎", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "我要拒絕！", style: .destructive, handler: { _ in
                self.viewModel.rejectAppointment(appointmentID: appointment.id ?? "")
                
                self.viewModel.appointments.remove(at: indexPath.row)
                
                tableView.deleteRows(at: [indexPath], with: .fade)
                
                let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
                feedbackGenerator.impactOccurred()
                
                completionHandler(true)
            }))
            
            alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: { _ in
                completionHandler(false)
            }))
            
            self.present(alert, animated: true, completion: nil)
        }
        
        return UISwipeActionsConfiguration(actions: [cancelAction])
    }
}

extension ConfirmVC {
    private func createEmptyStateView() -> UIView {
        let emptyView = UIView(frame: tableView.bounds)
        
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "tray")
        imageView.tintColor = .gray
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        let messageLabel = UILabel()
        messageLabel.text = "目前沒有任何預約"
        messageLabel.textColor = .gray
        messageLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        emptyView.addSubview(imageView)
        emptyView.addSubview(messageLabel)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: emptyView.centerYAnchor, constant: -20),
            imageView.widthAnchor.constraint(equalToConstant: 100),
            imageView.heightAnchor.constraint(equalToConstant: 100),
            
            messageLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            messageLabel.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor)
        ])
        
        return emptyView
    }
}
