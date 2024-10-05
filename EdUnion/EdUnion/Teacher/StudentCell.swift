//
//  StudentCell.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/10/5.
//

import UIKit

class StudentCell: UITableViewCell {
    
    let studentImageView = UIImageView()
    let nameLabel = UILabel()
    let blockButton = UIButton(type: .system)
    
    // 用於菜單動作的回調閉包
    var onBlockAction: (() -> Void)?
    var onAddNoteAction: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setupViews()
        setupConstraints()
    }
    
    private func setupViews() {
        studentImageView.contentMode = .scaleAspectFill
        studentImageView.clipsToBounds = true
        studentImageView.layer.cornerRadius = 20
        studentImageView.translatesAutoresizingMaskIntoConstraints = false
        
        nameLabel.font = UIFont.boldSystemFont(ofSize: 20)
        nameLabel.textColor = .black
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        blockButton.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        blockButton.tintColor = .black
        blockButton.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(studentImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(blockButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            studentImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            studentImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            studentImageView.widthAnchor.constraint(equalToConstant: 40),
            studentImageView.heightAnchor.constraint(equalToConstant: 40),
            
            nameLabel.leadingAnchor.constraint(equalTo: studentImageView.trailingAnchor, constant: 16),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            blockButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            blockButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            blockButton.widthAnchor.constraint(equalToConstant: 30),
            blockButton.heightAnchor.constraint(equalToConstant: 30),
            
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: blockButton.leadingAnchor, constant: -8)
        ])
    }
    
    func configure(with student: Student) {
        nameLabel.text = student.fullName
        
        if let photoURL = student.photoURL, let url = URL(string: photoURL) {
            studentImageView.kf.setImage(with: url, placeholder: UIImage(systemName: "person.crop.circle.fill"))
        } else {
            studentImageView.image = UIImage(systemName: "person.crop.circle.fill")
            studentImageView.tintColor = .myMessageCell
        }
        
        let blockAction = UIAction(title: "封鎖", image: UIImage(systemName: "hand.raised.fill"), attributes: .destructive) { [weak self] _ in
            self?.onBlockAction?()
        }
        
        let addNoteAction = UIAction(title: "新增備註", image: UIImage(systemName: "pencil")) { [weak self] _ in
            self?.onAddNoteAction?()
        }
        
        let menu = UIMenu(title: "", children: [blockAction, addNoteAction])
        blockButton.menu = menu
        blockButton.showsMenuAsPrimaryAction = true
    }
}
