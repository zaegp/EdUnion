//
//  TabBarController.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/14.
//

import UIKit

class TabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let firstVC = UINavigationController(rootViewController: StudentHomeVC())
        let secondVC = UINavigationController(rootViewController: CalendarVC())
//        let thirdVC = UINavigationController(rootViewController: StudentListVC())
        let fourthVC = UINavigationController(rootViewController: ProfileVC())
        firstVC.tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: "house"), selectedImage: UIImage(systemName: "house.fill"))
        secondVC.tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: "calendar"), selectedImage: UIImage(systemName: "calendar.fill"))
//        thirdVC.tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: "message"), selectedImage: UIImage(systemName: "message.fill"))
        fourthVC.tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: "person"), selectedImage: UIImage(systemName: "person.fill"))
        
        viewControllers = [firstVC, secondVC, fourthVC]
        
        tabBar.tintColor = UIColor(red: 0.92, green: 0.37, blue: 0.16, alpha: 1.00)
        tabBar.unselectedItemTintColor = .gray
        tabBar.barTintColor = .white
    }
}
