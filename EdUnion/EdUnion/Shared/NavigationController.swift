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
