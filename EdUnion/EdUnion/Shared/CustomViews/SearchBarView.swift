//
//  SearchBarView.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/10/3.
//

import UIKit

protocol SearchBarViewDelegate: AnyObject {
    func searchBarView(_ searchBarView: SearchBarView, didChangeText text: String)
    func searchBarViewDidCancel(_ searchBarView: SearchBarView)
}

class SearchBarView: UIView, UISearchBarDelegate {
    
    weak var delegate: SearchBarViewDelegate?
    
    private let searchBar = UISearchBar()
    private let cancelButton = UIButton(type: .system)
    
    private var searchBarWidthConstraint: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        searchBar.delegate = self
        searchBar.backgroundImage = UIImage()
        
        if let searchTextField = searchBar.searchTextField as? UITextField {
            searchTextField.backgroundColor = .clear
            searchTextField.layer.cornerRadius = 10
            searchTextField.clipsToBounds = true
            searchTextField.layer.borderWidth = 1.0
            searchTextField.layer.borderColor = UIColor.myGray.cgColor
            searchTextField.textColor = UIColor.myTint
            searchTextField.tintColor = UIColor.mainOrange
            
            let placeholderText = "搜尋"
            let attributes = [NSAttributedString.Key.foregroundColor: UIColor.myTint]
            searchTextField.attributedPlaceholder = NSAttributedString(string: placeholderText, attributes: attributes)
            
            if let leftIconView = searchTextField.leftView as? UIImageView {
                leftIconView.image = leftIconView.image?.withRenderingMode(.alwaysTemplate)
                leftIconView.tintColor = UIColor.myTint
            }
        }
        
        cancelButton.setTitle("取消", for: .normal)
        cancelButton.tintColor = .myTint
        cancelButton.isHidden = true
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        
        addSubview(searchBar)
        addSubview(cancelButton)
        
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        
        searchBarWidthConstraint = searchBar.widthAnchor.constraint(equalTo: widthAnchor)
        
        NSLayoutConstraint.activate([
            searchBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            searchBar.centerYAnchor.constraint(equalTo: centerYAnchor),
            searchBarWidthConstraint!,
            
            cancelButton.leadingAnchor.constraint(equalTo: searchBar.trailingAnchor),
            cancelButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            cancelButton.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    @objc private func cancelButtonTapped() {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        searchBarWidthConstraint?.isActive = false
        searchBarWidthConstraint = searchBar.widthAnchor.constraint(equalTo: widthAnchor)
        searchBarWidthConstraint?.isActive = true
        
        UIView.animate(withDuration: 0.3) {
            self.cancelButton.isHidden = true
            self.layoutIfNeeded()
        }
        
        delegate?.searchBarViewDidCancel(self)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        cancelButton.isHidden = false
        searchBarWidthConstraint?.isActive = false
        searchBarWidthConstraint = searchBar.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.85)
        searchBarWidthConstraint?.isActive = true
        
        UIView.animate(withDuration: 0.3) {
            self.layoutIfNeeded()
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        delegate?.searchBarView(self, didChangeText: searchText)
    }
    
    func hideKeyboardAndCancel() {
            searchBar.resignFirstResponder()
            
            searchBarWidthConstraint?.isActive = false
            searchBarWidthConstraint = searchBar.widthAnchor.constraint(equalTo: widthAnchor)
            searchBarWidthConstraint?.isActive = true
            
            UIView.animate(withDuration: 0.3) {
                self.cancelButton.isHidden = true
                self.layoutIfNeeded()
            }
        }
    
    func focusSearchBar() {
            searchBar.becomeFirstResponder()
        }
}
