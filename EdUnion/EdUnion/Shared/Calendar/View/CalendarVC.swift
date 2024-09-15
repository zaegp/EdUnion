//
//  CalendarVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/14.
//

import UIKit
import SwiftUI

class CalendarVC: UIViewController {

    private let calendarHostingController = UIHostingController(rootView: CalendarView())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        self.navigationItem.title = "Calendar"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareTapped))

        addChild(calendarHostingController)
        view.addSubview(calendarHostingController.view)
        calendarHostingController.didMove(toParent: self)
        
        setupConstraints()
    }
    
    @objc func shareTapped() {
            // 這是你想要分享的內容
        let itemsToShare = ["這是我要分享的內容", URL(string: "https://www.example.com")!] as [Any] // 可以分享文字或網址
            
            // 初始化 UIActivityViewController，並傳入要分享的內容
            let activityViewController = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
            
            // 如果需要排除某些分享選項，可以在這裡進行設置 (選擇性)
            activityViewController.excludedActivityTypes = [
                .print,              // 排除列印
                .assignToContact,    // 排除指定聯絡人
                .addToReadingList    // 排除加入閱讀列表
            ]
            
            // 在 iPad 上設置彈出方式 (針對 iPad 的 UI)
//            activityViewController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
            
            present(activityViewController, animated: true, completion: nil)
        }
    
    private func setupConstraints() {
        // Disable autoresizing mask translation for Auto Layout
        calendarHostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        // Layout constraints
        NSLayoutConstraint.activate([
            // 圆形进度条
            calendarHostingController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            calendarHostingController.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            calendarHostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            calendarHostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            calendarHostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            
           
        ])
    }

}


