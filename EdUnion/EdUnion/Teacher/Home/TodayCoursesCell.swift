//
//  TodayCoursesCell.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/18.
//

//import UIKit
//
//class TodayCoursesCell: UITableViewCell {
//    
//    let containerView: UIView = {
//        let view = UIView()
//        view.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.00)
//        view.layer.cornerRadius = 16
//        view.layer.shadowColor = UIColor(red: 1.00, green: 0.99, blue: 0.95, alpha: 1.00).cgColor
//        view.layer.shadowOpacity = 0.1
//        view.layer.shadowOffset = CGSize(width: 0, height: 2)
//        view.layer.shadowRadius = 4
//        view.translatesAutoresizingMaskIntoConstraints = false
//        return view
//    }()
//    
//    let topStackView: UIStackView = {
//        let stack = UIStackView()
//        stack.axis = .horizontal  // Horizontal arrangement of items
//        stack.alignment = .fill   // Makes sure the items fill the available space
//        stack.distribution = .equalSpacing  // Spaces the items equally across the width
//        stack.spacing = 8         // Sets a small gap between the items
//        stack.translatesAutoresizingMaskIntoConstraints = false
//        return stack
//    }()
//    
//    let stackView: UIStackView = {
//        let stack = UIStackView()
//        stack.axis = .vertical
//        stack.spacing = 8
//        stack.translatesAutoresizingMaskIntoConstraints = false
//        return stack
//    }()
//    
//    let nameLabel: UILabel = {
//        let label = UILabel()
//        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
//    
//    let timeLabel: UILabel = {
//        let label = UILabel()
//        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
//    
//    let noteLabel: UILabel = {
//        let label = UILabel()
//        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
//        label.numberOfLines = 0
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
//    
//    let confirmButton: UIButton = {
//        let button = UIButton(type: .system)
//        button.setImage(UIImage(systemName: "circle"), for: .normal)
//        //        button.layer.cornerRadius = 8
//        //        button.backgroundColor = UIColor(red: 0.15, green: 0.14, blue: 0.13, alpha: 1.00)
//        //        button.setTitleColor(UIColor(red: 1.00, green: 0.99, blue: 0.95, alpha: 1.00), for: .normal)
//        button.translatesAutoresizingMaskIntoConstraints = false
//        return button
//    }()
//    
//    var confirmCompletion: (() -> Void)?
//    
//    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
//        super.init(style: style, reuseIdentifier: reuseIdentifier)
//        
//        contentView.addSubview(containerView)
//        containerView.addSubview(stackView)
//        stackView.addArrangedSubview(topStackView)
//        stackView.addArrangedSubview(noteLabel)
//        topStackView.addArrangedSubview(nameLabel)
//        topStackView.addArrangedSubview(timeLabel)
//        topStackView.addArrangedSubview(confirmButton)
//        
//        setupConstraints()
//        
//        confirmButton.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
//        
//        selectionStyle = .none
//    }
//    
//    @objc private func confirmButtonTapped() {
//        confirmCompletion?()
//    }
//    
//    private func setupConstraints() {
//        NSLayoutConstraint.activate([
//            // Constraints for the containerView
//            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
//            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
//            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
//            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
//            
//            // Constraints for the stackView, which contains the topStackView and the noteLabel
//            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
//            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
//            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
//            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
//            
//            // Constraints for the topStackView (contains nameLabel, timeLabel, and confirmButton)
//            topStackView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
//            topStackView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
//            topStackView.heightAnchor.constraint(equalToConstant: 25),  // Adjust as needed
//            
//            // Constraints for the nameLabel
//            nameLabel.leadingAnchor.constraint(equalTo: topStackView.leadingAnchor),
//            nameLabel.centerYAnchor.constraint(equalTo: topStackView.centerYAnchor),
//            
//            // Constraints for the timeLabel
//            timeLabel.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 16),
//            timeLabel.centerYAnchor.constraint(equalTo: topStackView.centerYAnchor),
//            
//            // Constraints for the confirmButton
//            confirmButton.trailingAnchor.constraint(equalTo: topStackView.trailingAnchor),
//            confirmButton.centerYAnchor.constraint(equalTo: topStackView.centerYAnchor),
//            
//            // Constraints for the noteLabel (hidden initially if not expanded)
//            noteLabel.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
//            noteLabel.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
//        ])
//    }
//    
//    func configureCell(name: String, times: [String], note: String, isExpanded: Bool) {
//        nameLabel.text = name
//        timeLabel.text = TimeService.convertCourseTimeToDisplay(from: times)
//        noteLabel.text = note
//        noteLabel.isHidden = !isExpanded
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//}

import UIKit

class TodayCoursesCell: UITableViewCell {
    
    let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.00)
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor(red: 1.00, green: 0.99, blue: 0.95, alpha: 1.00).cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let noteLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let confirmButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "circle"), for: .normal)
//        button.layer.cornerRadius = 8
//        button.backgroundColor = UIColor(red: 0.15, green: 0.14, blue: 0.13, alpha: 1.00)
//        button.setTitleColor(UIColor(red: 1.00, green: 0.99, blue: 0.95, alpha: 1.00), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    var confirmCompletion: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(containerView)
        containerView.addSubview(nameLabel)
        containerView.addSubview(timeLabel)
        containerView.addSubview(noteLabel)
        containerView.addSubview(confirmButton)
        
        setupConstraints()
        
        confirmButton.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
        
        selectionStyle = .none
    }
    
    @objc private func confirmButtonTapped() {
        confirmCompletion?()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 25),
            
            timeLabel.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 16),
            timeLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 25),
            
            noteLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 52),
            noteLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            
            confirmButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
//            confirmButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 25)
            confirmButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
    }
    
    func configureCell(name: String, times: [String], note: String, isExpanded: Bool) {
        timeLabel.text = ""
        
        nameLabel.text = name
        timeLabel.text = TimeService.convertCourseTimeToDisplay(from: times)
        noteLabel.text = note
        noteLabel.isHidden = !isExpanded
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

