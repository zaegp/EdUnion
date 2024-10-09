//
//  UIViewController+Ext.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/23.
//

import UIKit

extension UIViewController {
    func setupKeyboardDismissRecognizer() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self as? UIGestureRecognizerDelegate  
        view.addGestureRecognizer(tapGesture)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

// MARK: - 手勢返回前一頁
extension UIViewController {
    
    func enableSwipeToGoBack() {
        let swipeGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleSwipeGesture(_:)))
        swipeGesture.edges = .left
        view.addGestureRecognizer(swipeGesture)
    }
    
    @objc private func handleSwipeGesture(_ gesture: UIScreenEdgePanGestureRecognizer) {
        if gesture.state == .recognized {
            navigationController?.popViewController(animated: true)
        }
    }
}
