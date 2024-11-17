//
//  TabBarController.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/14.
//

import UIKit

class TabBarController: UITabBarController {
    
    // MARK: - Properties
    private var customTabBarView: UIView!
    private var tabBarButtons: [UIButton] = []
    private var userRole: String
    private var selectedBackgroundView: UIView!
    private let tabBarButtonImages = ["house", "calendar", "message", "person"]

    // MARK: - Initializer
    init(userRole: String) {
        self.userRole = userRole
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
        setupViewControllers()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutCustomTabBar()
    }

    // MARK: - Setup
    private func setupTabBar() {
        tabBar.isHidden = true
        createCustomTabBar()
        createTabBarButtons()
        updateSelectedTab(index: 0)
    }

    private func createCustomTabBar() {
        let height: CGFloat = 60
        customTabBarView = UIView(frame: CGRect(x: 20, y: view.frame.height - height - 20, width: view.frame.width - 40, height: height))
        customTabBarView.backgroundColor = .myDarkGray
        customTabBarView.layer.cornerRadius = height / 2
        customTabBarView.layer.applyShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 5), radius: 10)
        
        let selectedHeight: CGFloat = height - 10
        let buttonWidth = customTabBarView.frame.width / CGFloat(tabBarButtonImages.count)
        let selectedWidth: CGFloat = buttonWidth - 20
        
        selectedBackgroundView = UIView(frame: CGRect(x: (buttonWidth - selectedWidth) / 2, y: (height - selectedHeight) / 2, width: selectedWidth, height: selectedHeight))
        selectedBackgroundView.backgroundColor = .myBackground
        selectedBackgroundView.layer.cornerRadius = selectedHeight / 2
        
        customTabBarView.addSubview(selectedBackgroundView)
        view.addSubview(customTabBarView)
    }

    private func createTabBarButtons() {
        let buttonWidth = customTabBarView.frame.width / CGFloat(tabBarButtonImages.count)
        
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
    }

    private func setupViewControllers() {
        let firstVC: UIViewController = userRole == "teacher" ? TodayCoursesVC() : StudentHomeVC()
        let viewControllers = [
            NavigationController(rootViewController: firstVC),
            NavigationController(rootViewController: CalendarVC()),
            NavigationController(rootViewController: ChatListVC()),
            NavigationController(rootViewController: ProfileVC())
        ]

        self.viewControllers = viewControllers.enumerated().map { index, vc in
            vc.tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: tabBarButtonImages[index]), tag: index)
            return vc
        }
    }

    private func layoutCustomTabBar() {
        let height: CGFloat = 60
        customTabBarView.frame = CGRect(x: 20, y: view.frame.height - height - 20, width: view.frame.width - 40, height: height)
    }

    // MARK: - Tab Bar Actions
    @objc private func tabBarButtonTapped(_ sender: UIButton) {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        feedbackGenerator.impactOccurred()
        
        updateSelectedTab(index: sender.tag)
        selectedIndex = sender.tag
    }

    private func updateSelectedTab(index: Int) {
        let buttonWidth = customTabBarView.frame.width / CGFloat(tabBarButtons.count)
        let selectedWidth: CGFloat = buttonWidth - 20

        UIView.animate(withDuration: 0.3) {
            self.selectedBackgroundView.frame.origin.x = CGFloat(index) * buttonWidth + (buttonWidth - selectedWidth) / 2
        }

        for (i, button) in tabBarButtons.enumerated() {
            UIView.animate(withDuration: 0.3) {
                button.transform = (i == index) ? CGAffineTransform(scaleX: 1.1, y: 1.1) : .identity
                button.tintColor = (i == index) ? .label : .gray
            }
        }
    }

    // MARK: - Show/Hide Tab Bar
    func setCustomTabBarHidden(_ hidden: Bool, animated: Bool) {
        let animationBlock = { self.customTabBarView.alpha = hidden ? 0 : 1 }
        animated ? UIView.animate(withDuration: 0.3, animations: animationBlock) : animationBlock()
    }
}

// MARK: - Extensions
extension CALayer {
    func applyShadow(color: UIColor, opacity: Float, offset: CGSize, radius: CGFloat) {
        shadowColor = color.cgColor
        shadowOpacity = opacity
        shadowOffset = offset
        shadowRadius = radius
    }
}
