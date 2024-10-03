//
//  TabBarController.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/14.
//

import UIKit

class TabBarController: UITabBarController {
    
    private var customTabBarView: UIView!
    private var tabBarButtons: [UIButton] = []
    private var userRole: String

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
        tabBar.isHidden = true

        let height: CGFloat = 60
        customTabBarView = UIView(frame: CGRect(x: 20, y: view.frame.height - height - 20, width: view.frame.width - 40, height: height))
        customTabBarView.backgroundColor = .myDarkGray
        customTabBarView.layer.cornerRadius = height / 2
        customTabBarView.layer.shadowColor = UIColor.black.cgColor
        customTabBarView.layer.shadowOpacity = 0.2
        customTabBarView.layer.shadowOffset = CGSize(width: 0, height: 5)
        customTabBarView.layer.shadowRadius = 10
        
        view.addSubview(customTabBarView)

        let tabBarButtonImages = ["house", "calendar", "message", "person"]
        let numberOfButtons = tabBarButtonImages.count
        let buttonWidth = customTabBarView.frame.width / CGFloat(numberOfButtons)

        for (index, imageName) in tabBarButtonImages.enumerated() {
            let button = UIButton(type: .custom)
            button.frame = CGRect(x: CGFloat(index) * buttonWidth, y: 0, width: buttonWidth, height: customTabBarView.frame.height)
            button.setImage(UIImage(systemName: imageName), for: .normal)
            button.tintColor = .gray
            button.tag = index
            button.addTarget(self, action: #selector(tabBarButtonTapped(_:)), for: .touchUpInside)
            customTabBarView.addSubview(button)
            tabBarButtons.append(button)
        }
        
        updateSelectedTab(index: 0)
    }

    @objc private func tabBarButtonTapped(_ sender: UIButton) {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        feedbackGenerator.impactOccurred()
        
        updateSelectedTab(index: sender.tag)
        selectedIndex = sender.tag
    }

    private func updateSelectedTab(index: Int) {
        for (i, button) in tabBarButtons.enumerated() {
            if i == index {
                UIView.animate(withDuration: 0.3, animations: {
                    button.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                    button.tintColor = UIColor(red: 0.92, green: 0.37, blue: 0.16, alpha: 1.00)
                })
            } else {
                UIView.animate(withDuration: 0.3, animations: {
                    button.transform = CGAffineTransform.identity
                    button.tintColor = .gray 
                })
            }
        }
    }

    private func setupViewControllers() {
        var firstVC = NavigationController(rootViewController: StudentHomeVC())
        if userRole == "teacher" {
            firstVC = NavigationController(rootViewController: TodayCoursesVC())
        }
        firstVC.tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: "house"), tag: 0)

        let secondVC = NavigationController(rootViewController: CalendarVC())
        secondVC.tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: "calendar"), tag: 1)

        let thirdVC = NavigationController(rootViewController: ChatListVC())
        thirdVC.tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: "message"), tag: 2)

        let fourthVC = NavigationController(rootViewController: ProfileVC())
        fourthVC.tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: "person"), tag: 3)

        viewControllers = [firstVC, secondVC, thirdVC, fourthVC]
    }
    
    func setCustomTabBarHidden(_ hidden: Bool, animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.3) {
                self.customTabBarView.alpha = hidden ? 0 : 1
            }
        } else {
            customTabBarView.alpha = hidden ? 0 : 1
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let height: CGFloat = 60
        customTabBarView.frame = CGRect(x: 20, y: view.frame.height - height - 20, width: view.frame.width - 40, height: height)
    }
}
