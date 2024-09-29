//
//  TabBarController.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/14.
//

import UIKit

class TabBarController: UITabBarController {
    
    private var customTabBarView: UIView!
    var userRole: String
        
        init(userRole: String) {
            self.userRole = userRole
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTabBar()
        setupViewControllers()
    }
    
    private func setupTabBar() {
        // 隱藏原始的 TabBar
        tabBar.isHidden = true
        
        // 自定義的 TabBar 視圖
        let height: CGFloat = 80
        customTabBarView = UIView(frame: CGRect(x: 20, y: view.frame.height - height - 20, width: view.frame.width - 40, height: height))
        customTabBarView.backgroundColor = .white
        customTabBarView.layer.cornerRadius = height / 2
        customTabBarView.layer.shadowColor = UIColor.black.cgColor
        customTabBarView.layer.shadowOpacity = 0.2
        customTabBarView.layer.shadowOffset = CGSize(width: 0, height: 5)
        customTabBarView.layer.shadowRadius = 10
        
        // 添加到主視圖中
        view.addSubview(customTabBarView)
        
        // 添加 TabBar 按鈕
        let tabBarButtonImages = ["house", "cube.box", "checkmark.circle", "chart.bar", "ellipsis"]
        let numberOfButtons = tabBarButtonImages.count
        let buttonWidth = customTabBarView.frame.width / CGFloat(numberOfButtons)
        
        for (index, imageName) in tabBarButtonImages.enumerated() {
            let button = UIButton(type: .custom)
            button.frame = CGRect(x: CGFloat(index) * buttonWidth, y: 0, width: buttonWidth, height: customTabBarView.frame.height)
            button.setImage(UIImage(systemName: imageName), for: .normal)
            button.tintColor = .black
            button.tag = index
            button.addTarget(self, action: #selector(tabBarButtonTapped(_:)), for: .touchUpInside)
            customTabBarView.addSubview(button)
        }
    }
    
    @objc private func tabBarButtonTapped(_ sender: UIButton) {
        selectedIndex = sender.tag
    }
    
    private func setupViewControllers() {
        var firstVC = NavigationController(rootViewController: StudentHomeVC())
        if userRole == "teacher" {
            firstVC = NavigationController(rootViewController: TodayCoursesVC())
        }
        firstVC.tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: "house"), tag: 0)
        
        let secondVC = NavigationController(rootViewController: UIViewController())
        secondVC.tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: "cube.box"), tag: 1)
        
        let thirdVC = NavigationController(rootViewController: UIViewController())
        thirdVC.tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: "checkmark.circle"), tag: 2)
        
        let fourthVC = NavigationController(rootViewController: UIViewController())
        fourthVC.tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: "chart.bar"), tag: 3)
        
        let fifthVC = NavigationController(rootViewController: UIViewController())
        fifthVC.tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: "ellipsis"), tag: 4)
        
        viewControllers = [firstVC, secondVC, thirdVC, fourthVC, fifthVC]
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 更新自定義 TabBar 視圖的位置
        let height: CGFloat = 80
        customTabBarView.frame = CGRect(x: 20, y: view.frame.height - height - 20, width: view.frame.width - 40, height: height)
    }
}
