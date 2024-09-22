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
        
        addChild(calendarHostingController)
        view.addSubview(calendarHostingController.view)
        calendarHostingController.didMove(toParent: self)
        setupConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
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


