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
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}
