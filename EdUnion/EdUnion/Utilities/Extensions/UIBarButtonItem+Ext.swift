//
//  UIBarButtonItem+Ext.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/10/10.
//

import UIKit

extension UIBarButtonItem {
    
    func addBadge(number: Int) {
        removeBadge()
        
        guard number > 0 else { return }
        
        let badgeLabel = UILabel()
        badgeLabel.text = "\(number)"
        badgeLabel.font = UIFont.systemFont(ofSize: 12)
        badgeLabel.textColor = .white
        badgeLabel.backgroundColor = .red
        badgeLabel.textAlignment = .center
        badgeLabel.layer.cornerRadius = 10
        badgeLabel.layer.masksToBounds = true
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        badgeLabel.tag = 99
        
        if let customView = self.customView {
            customView.addSubview(badgeLabel)
            
            NSLayoutConstraint.activate([
                badgeLabel.topAnchor.constraint(equalTo: customView.topAnchor, constant: -5),
                badgeLabel.trailingAnchor.constraint(equalTo: customView.trailingAnchor, constant: 5),
                badgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 20),
                badgeLabel.heightAnchor.constraint(equalToConstant: 20)
            ])
        } else {
            let buttonView = UIView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
            buttonView.addSubview(badgeLabel)
            
            NSLayoutConstraint.activate([
                badgeLabel.topAnchor.constraint(equalTo: buttonView.topAnchor, constant: -5),
                badgeLabel.trailingAnchor.constraint(equalTo: buttonView.trailingAnchor, constant: 5),
                badgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 20),
                badgeLabel.heightAnchor.constraint(equalToConstant: 20)
            ])
            
            self.customView = buttonView
        }
    }
    
    func removeBadge() {
        self.customView?.subviews.filter { $0.tag == 99 }.forEach { $0.removeFromSuperview() }
    }
}
