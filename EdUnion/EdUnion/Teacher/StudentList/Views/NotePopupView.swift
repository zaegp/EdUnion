//
//  NotePopupView.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/10/5.
//

import UIKit

class NotePopupView: UIView {
    
    private let containerView = UIView()
    private let textView = UITextView()
    private let saveButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    
    var onSave: ((String) -> Void)?
    
    var onCancel: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupBackgroundView()
        setupContainerView()
        setupTextView()
        setupButtons()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setupBackgroundView()
        setupContainerView()
        setupTextView()
        setupButtons()
    }
    
    private func setupBackgroundView() {
        self.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        self.addGestureRecognizer(tapGesture)
    }
    
    private func setupContainerView() {
        containerView.backgroundColor = .myBackground
        containerView.layer.cornerRadius = 12
        containerView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(containerView)
        
        NSLayoutConstraint.activate([
            containerView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            containerView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            containerView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.8)
        ])
    }
    
    private func setupTextView() {
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.layer.borderColor = UIColor.myGray.cgColor
        textView.layer.borderWidth = 1.0
        textView.layer.cornerRadius = 8
        textView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(textView)
        
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            textView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            textView.heightAnchor.constraint(equalToConstant: 200)
        ])
    }
    
    private func setupButtons() {
        saveButton.setTitle("保存", for: .normal)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.backgroundColor = .mainOrange
        saveButton.layer.cornerRadius = 8
        saveButton.layer.masksToBounds = true
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(saveButton)
        
        NSLayoutConstraint.activate([
            saveButton.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 16),
            saveButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            saveButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            saveButton.widthAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    @objc private func saveButtonTapped() {
        onSave?(textView.text)
    }
    
    @objc private func cancelButtonTapped() {
        onCancel?()
    }
    
    @objc private func backgroundTapped() {
        onCancel?()
    }
    
    func setExistingNoteText(_ text: String) {
        textView.text = text
    }
}
