//
//  AvailableTimeSlotsCell.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/13.
//

import UIKit

class AvailableTimeSlotsCell: UITableViewCell {
    
    let colorView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()
    
    let timeRangesLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.numberOfLines = 0
        return label
    }()
    
    let containerStackView = UIStackView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        containerStackView.axis = .horizontal
        containerStackView.spacing = 16
        containerStackView.alignment = .center
        containerStackView.addArrangedSubview(colorView)
        containerStackView.addArrangedSubview(timeRangesLabel)
        
        contentView.addSubview(containerStackView)
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            colorView.widthAnchor.constraint(equalToConstant: 50),
            colorView.heightAnchor.constraint(equalToConstant: 50),
            
            containerStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
        
        // 設置 cell 和 colorView 的背景色
        contentView.backgroundColor = .clear
        colorView.backgroundColor = .clear
        
        let arrowIcon = UIImageView(image: UIImage(systemName: "arrow.forward"))
        arrowIcon.tintColor = .myBlack
        accessoryView = arrowIcon
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // 設置 colorView 為圓形
        colorView.layer.cornerRadius = colorView.frame.size.width / 2

        // 設置 cell 的圓角
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true

        // 設置陰影效果
//        layer.shadowColor = UIColor.black.cgColor
//        layer.shadowOpacity = 0.1
//        layer.shadowOffset = CGSize(width: 0, height: 2)
//        layer.shadowRadius = 4
//        layer.masksToBounds = false
    }
    
    func configure(with timeSlot: AvailableTimeSlot) {
        let color = UIColor(hexString: timeSlot.colorHex)
        colorView.backgroundColor = color
        
        let timeRangesText = timeSlot.timeRanges.joined(separator: "\n")
        timeRangesLabel.text = timeRangesText
    }
}
