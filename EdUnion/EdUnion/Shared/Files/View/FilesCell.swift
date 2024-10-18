//
//  FilesCell.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/30.
//

//import UIKit
//
//class FileCell: UICollectionViewCell {
//    let imageView = UIImageView()
//    let nameLabel = UILabel()
//    let activityIndicator = UIActivityIndicatorView(style: .medium)
//
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//
//        imageView.contentMode = .scaleAspectFit
//        imageView.tintColor = .mainOrange
//        imageView.translatesAutoresizingMaskIntoConstraints = false
//        contentView.addSubview(imageView)
//
//        nameLabel.font = UIFont.systemFont(ofSize: 12)
//        nameLabel.textAlignment = .center
//        nameLabel.translatesAutoresizingMaskIntoConstraints = false
//        contentView.addSubview(nameLabel)
//
//        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
//                contentView.addSubview(activityIndicator)
//
//        NSLayoutConstraint.activate([
//            imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
//            imageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
//            imageView.widthAnchor.constraint(equalToConstant: 50),
//            imageView.heightAnchor.constraint(equalToConstant: 50),
//
//            nameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 5),
//            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5),
//            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5),
//
//            activityIndicator.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
//                        activityIndicator.centerYAnchor.constraint(equalTo: imageView.centerYAnchor)
//        ])
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    func configure(with fileURL: URL, isDownloading: Bool) {
//        nameLabel.text = fileURL.lastPathComponent
//        imageView.image = UIImage(systemName: isDownloading ? "arrow.down.doc" : "doc")
//        if isDownloading {
//                    activityIndicator.startAnimating()
//                } else {
//                    activityIndicator.stopAnimating()
//                }
//    }
//
//    func setSelected(_ selected: Bool) {
//        imageView.image = selected ? UIImage(systemName: "doc.fill") : UIImage(systemName: "doc")
//    }
//}

import UIKit

protocol FileCellDelegate: AnyObject {
    func fileCellDidRequestDelete(_ cell: FileCell)
    func fileCellDidRequestEditName(_ cell: FileCell)
}

class FileCell: UICollectionViewCell {
    
    let fileImageView = UIImageView()
    let fileNameLabel = UILabel()
    let progressView = UIProgressView(progressViewStyle: .default)
    
    weak var delegate: FileCellDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.backgroundColor = .clear
        backgroundColor = .myBackground
        
        fileImageView.tintColor = .mainOrange
        fileImageView.contentMode = .scaleAspectFit
        fileImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(fileImageView)
        
        fileNameLabel.textAlignment = .center
        fileNameLabel.font = UIFont.systemFont(ofSize: 12)
        fileNameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(fileNameLabel)
        
        progressView.isHidden = true
        progressView.progress = 0.0
        contentView.addSubview(progressView)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            fileImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            fileImageView.bottomAnchor.constraint(equalTo: fileNameLabel.topAnchor, constant: -5),
            fileImageView.widthAnchor.constraint(equalToConstant: 48),
            fileImageView.heightAnchor.constraint(equalToConstant: 48), 
            
            fileNameLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            fileNameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            fileNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5),
            fileNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5),
            
            progressView.topAnchor.constraint(equalTo: fileNameLabel.bottomAnchor, constant: 5),
            progressView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 4)
        ])
        
        
        self.addInteraction(UIContextMenuInteraction(delegate: self))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        progressView.setProgress(0.0, animated: false)
        progressView.isHidden = true
    }
    
    override var isSelected: Bool {
        didSet {
            if let collectionView = superview as? UICollectionView, collectionView.allowsMultipleSelection {
                fileImageView.image = isSelected ? UIImage(systemName: "doc.fill") : UIImage(systemName: "doc")
            }
        }
    }
    
    func configure(with fileItem: FileItem, isDownloading: Bool, allowsMultipleSelection: Bool) {
        fileNameLabel.text = fileItem.fileName
        if allowsMultipleSelection {
                fileImageView.image = isSelected ? UIImage(systemName: "doc.fill") : UIImage(systemName: "doc")
            } else {
                fileImageView.image = UIImage(systemName: "doc")
            }
        progressView.isHidden = !isDownloading
    }
    
    func updateProgress(_ progress: Float) {
        progressView.progress = progress
        
    }
    
    func hideProgress() {
        progressView.isHidden = true
    }
    
    @objc func deleteButtonTapped() {
        delegate?.fileCellDidRequestDelete(self)
    }
    
    @objc func editButtonTapped() {
        delegate?.fileCellDidRequestEditName(self)
    }
}

extension FileCell: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let editAction = UIAction(title: "編輯文件名稱", image: UIImage(systemName: "pencil")) { [weak self] _ in
                guard let self = self else { return }
                self.delegate?.fileCellDidRequestEditName(self)
            }
            
            let deleteAction = UIAction(title: "刪除文件", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
                guard let self = self else { return }
                self.delegate?.fileCellDidRequestDelete(self)
            }
            
            return UIMenu(title: "", children: [editAction, deleteAction])
        }
    }
}
