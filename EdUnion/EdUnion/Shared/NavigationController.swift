//
//  NavigationController.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/22.
//

import UIKit

class NavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationBar.backIndicatorImage = UIImage()
        navigationBar.backIndicatorTransitionMaskImage = UIImage()
    }
    
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        super.pushViewController(viewController, animated: animated)
        
        if viewControllers.count > 1 {
            viewController.navigationItem.backButtonDisplayMode = .minimal
            let backButton = UIBarButtonItem(image: UIImage(systemName: "chevron.backward"), style: .plain, target: self, action: #selector(handleBackButton))
            backButton.tintColor = .backButton
            viewController.navigationItem.leftBarButtonItem = backButton
        }
    }
    
    @objc private func handleBackButton() {
        popViewController(animated: true)
    }
}


//class NavigationController: UINavigationController {
//
//    private let bottomLine = UIView()
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        // 自定義返回按鈕圖像
//        navigationBar.backIndicatorImage = UIImage()
//        navigationBar.backIndicatorTransitionMaskImage = UIImage()
//        
//        // 添加底部線條
//        addBottomLine()
//    }
//
//    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
//        super.pushViewController(viewController, animated: animated)
//
//        if viewControllers.count > 1 {
//            viewController.navigationItem.backButtonDisplayMode = .minimal
//            let backButton = UIBarButtonItem(image: UIImage(systemName: "chevron.backward"), style: .plain, target: self, action: #selector(handleBackButton))
//            backButton.tintColor = .black
//            viewController.navigationItem.leftBarButtonItem = backButton
//        }
//    }
//
//    @objc private func handleBackButton() {
//        popViewController(animated: true)
//    }
//
//    private func addBottomLine() {
//        // 設置底部線條的顏色和高度
//        bottomLine.backgroundColor = UIColor.gray
//        bottomLine.translatesAutoresizingMaskIntoConstraints = false
//
//        // 添加到底部
//        navigationBar.addSubview(bottomLine)
//
//        // 設置底部線條的約束
//        NSLayoutConstraint.activate([
//            bottomLine.heightAnchor.constraint(equalToConstant: 1), // 設置線條高度
//            bottomLine.bottomAnchor.constraint(equalTo: navigationBar.bottomAnchor),
//            bottomLine.leadingAnchor.constraint(equalTo: navigationBar.leadingAnchor),
//            bottomLine.trailingAnchor.constraint(equalTo: navigationBar.trailingAnchor)
//        ])
//    }
//
//    // 控制底部線條的方法
//    func setBottomLine(isHidden: Bool, color: UIColor? = nil) {
//        bottomLine.isHidden = isHidden
//        if let color = color {
//            bottomLine.backgroundColor = color
//        }
//    }
//}
