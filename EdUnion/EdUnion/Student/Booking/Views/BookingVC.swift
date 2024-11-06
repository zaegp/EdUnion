//
//  BookingVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/15.
//

import UIKit
import SwiftUI

class BookingVC: UIViewController {
    
    var teacher: Teacher?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let selectedTimeSlots = teacher?.selectedTimeSlots, let timeSlots = teacher?.timeSlots else {
            print("Teacher's selected time slots or time slots are missing.")
            return
        }
        
        enableSwipeToGoBack()
        setupBookingView(teacherID: teacher?.id ?? "", selectedTimeSlots: selectedTimeSlots, timeSlots: timeSlots)
    }
    
    func setupBookingView(teacherID: String, selectedTimeSlots: [String: String], timeSlots: [AvailableTimeSlot]) {
        let bookingView = BookingView(viewModel: BookingViewModel(teacherID: teacherID, timeSlots: timeSlots, selectedTimeSlots: selectedTimeSlots))
        let hostingController = UIHostingController(rootView: bookingView)
        
        addChild(hostingController)
        view.addSubview(hostingController.view)
        
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        hostingController.didMove(toParent: self)
    }
    
}
