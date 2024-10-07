//
//  ConfirmCell.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/16.
//

import UIKit

class ConfirmCell: UITableViewCell {
    
    let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .myCell
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        label.textColor = .black
        label.textAlignment = .center
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let newStudentLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = .black
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var confirmCompletion: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(containerView)
        containerView.addSubview(dateLabel)
        containerView.addSubview(separatorView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(timeLabel)
        containerView.addSubview(newStudentLabel)
        
        setupConstraints()
        selectionStyle = .none
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            dateLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            dateLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            dateLabel.widthAnchor.constraint(equalToConstant: 50),
            
            separatorView.leadingAnchor.constraint(equalTo: dateLabel.trailingAnchor, constant: 16),
            separatorView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            separatorView.widthAnchor.constraint(equalToConstant: 0.5),
            separatorView.heightAnchor.constraint(equalToConstant: 40),
            
            titleLabel.leadingAnchor.constraint(equalTo: separatorView.trailingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            timeLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 16),
            timeLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            newStudentLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            newStudentLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
            
        ])
    }
    
    func configureCell(date: String, title: String, times: [String], isStudentExisting: Bool) {
        dateLabel.text = TimeService.covertToEnMonth(date)
        titleLabel.text = title
        timeLabel.text = TimeService.convertCourseTimeToDisplay(from: times)
        newStudentLabel.isHidden = isStudentExisting
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
