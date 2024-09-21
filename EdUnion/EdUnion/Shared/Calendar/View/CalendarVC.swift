//
//  CalendarVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/14.
//

import UIKit
import SwiftUI

class CalendarVC: UIViewController {
    
    private let calendarHostingController = UIHostingController(rootView: BaseCalendarView(externalDateColors: .constant(nil), viewModel: BaseCalendarViewModel()))
//    private let calendarHostingController = UIHostingController(rootView: ColorPickerCalendarView())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareTapped))
        
        addChild(calendarHostingController)
        view.addSubview(calendarHostingController.view)
        calendarHostingController.didMove(toParent: self)
        setupConstraints()
    }
    
    @objc func shareTapped() {
        let itemsToShare = ["這是我要分享的內容", URL(string: "https://www.example.com")!] as [Any]
        
        let activityViewController = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
        
        activityViewController.excludedActivityTypes = [
            .print,
            .assignToContact,
            .addToReadingList
        ]
        
        present(activityViewController, animated: true, completion: nil)
    }
    
    private func setupConstraints() {
        calendarHostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            calendarHostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            calendarHostingController.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            calendarHostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            calendarHostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            calendarHostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
}


