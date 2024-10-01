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
        updateSelectedTab(index: 0)
    }

    private func setupTabBar() {
        tabBar.isHidden = true

        let height: CGFloat = 80
        customTabBarView = UIView(frame: CGRect(x: 20, y: view.frame.height - height - 20, width: view.frame.width - 40, height: height))
        customTabBarView.backgroundColor = .white
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
            button.tintColor = .gray // 默认未选中颜色
            button.tag = index
            button.addTarget(self, action: #selector(tabBarButtonTapped(_:)), for: .touchUpInside)
            customTabBarView.addSubview(button)
            tabBarButtons.append(button)
        }
    }

    @objc private func tabBarButtonTapped(_ sender: UIButton) {
        updateSelectedTab(index: sender.tag)
        selectedIndex = sender.tag
    }

    private func updateSelectedTab(index: Int) {
        for (i, button) in tabBarButtons.enumerated() {
            if i == index {
                UIView.animate(withDuration: 0.3, animations: {
                    button.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                    
                    let circleSize: CGFloat = 30
                    let circleLayer = CAShapeLayer()
                    let circlePath = UIBezierPath(ovalIn: CGRect(x: (button.bounds.width - circleSize) / 2,
                                                                 y: (button.bounds.height - circleSize) / 2,
                                                                 width: circleSize,
                                                                 height: circleSize))
                    circleLayer.path = circlePath.cgPath
                    circleLayer.fillColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.00).cgColor
                    
                    if let sublayers = button.layer.sublayers {
                        for layer in sublayers {
                            if layer is CAShapeLayer {
                                layer.removeFromSuperlayer()
                            }
                        }
                    }
                    
                    button.layer.insertSublayer(circleLayer, at: 0)
                    
                    button.tintColor = UIColor(red: 0.92, green: 0.37, blue: 0.16, alpha: 1.00)
                })
            } else {
                UIView.animate(withDuration: 0.3, animations: {
                    button.transform = CGAffineTransform.identity
                    button.tintColor = .gray
                    
                    if let sublayers = button.layer.sublayers {
                        for layer in sublayers {
                            if layer is CAShapeLayer {
                                layer.removeFromSuperlayer()
                            }
                        }
                    }
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
        let height: CGFloat = 80
        customTabBarView.frame = CGRect(x: 20, y: view.frame.height - height - 20, width: view.frame.width - 40, height: height)
    }
}
