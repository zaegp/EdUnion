//
//  BedgeButton.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/10/10.
//

import UIKit

class BadgeButton: UIButton {
    private let badgeLabel = UILabel()
    
    var badgeNumber: Int = 0 {
        didSet {
            updateBadge()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupBadge()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupBadge()
    }
    
    private func setupBadge() {
        badgeLabel.backgroundColor = .mainOrange
        badgeLabel.textColor = .white
        badgeLabel.font = UIFont.systemFont(ofSize: 12)
        badgeLabel.textAlignment = .center
        badgeLabel.layer.cornerRadius = 10
        badgeLabel.clipsToBounds = true
        badgeLabel.isHidden = true
        addSubview(badgeLabel)
        
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            badgeLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: -5),
            badgeLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 5),
            badgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 20),
            badgeLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    func setBadge(number: Int) {
        badgeNumber = number
    }
    
    private func updateBadge() {
        if badgeNumber > 0 {
            badgeLabel.text = "\(badgeNumber)"
            badgeLabel.isHidden = false
        } else {
            badgeLabel.isHidden = true
        }
    }
}
