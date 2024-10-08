//
//  PaddedTextField.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/10/3.
//

import UIKit

class PaddedTextField: UITextField {
    
    var horizontalPadding: CGFloat = 8
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: horizontalPadding, dy: 0)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: horizontalPadding, dy: 0)
    }
}
