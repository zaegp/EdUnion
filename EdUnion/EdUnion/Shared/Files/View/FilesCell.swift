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
    
    // 新增的 UIImageView
    let fileImageView = UIImageView()
    let fileNameLabel = UILabel()
    let downloadIndicator = UIActivityIndicatorView(style: .medium)
    weak var delegate: FileCellDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // 配置 fileImageView
        fileImageView.contentMode = .scaleAspectFit
        fileImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(fileImageView)
        
        // 配置 fileNameLabel
        fileNameLabel.textAlignment = .center
        fileNameLabel.numberOfLines = 2
        fileNameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(fileNameLabel)
        
        // 配置 downloadIndicator
        downloadIndicator.hidesWhenStopped = true
        downloadIndicator.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(downloadIndicator)
        
        // 設置約束
        NSLayoutConstraint.activate([
            // fileImageView 放置在 fileNameLabel 上方，水平居中
            fileImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            fileImageView.bottomAnchor.constraint(equalTo: fileNameLabel.topAnchor, constant: -5),
            fileImageView.widthAnchor.constraint(equalToConstant: 24), // 設定合適的寬度
            fileImageView.heightAnchor.constraint(equalToConstant: 24), // 設定合適的高度
            
            // fileNameLabel 保持中心位置
            fileNameLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            fileNameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            fileNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5),
            fileNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5),
            
            // downloadIndicator 在 fileNameLabel 下方，水平居中
            downloadIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            downloadIndicator.topAnchor.constraint(equalTo: fileNameLabel.bottomAnchor, constant: 5)
        ])
        
        // 添加長按手勢以觸發上下文菜單
        if #available(iOS 13.0, *) {
            self.addInteraction(UIContextMenuInteraction(delegate: self))
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 配置 cell 的方法
    /// - Parameters:
    ///   - fileURL: 文件的 URL
    ///   - isDownloading: 文件是否正在下載
    func configure(with fileURL: URL, isDownloading: Bool) {
        fileNameLabel.text = fileURL.lastPathComponent
        if isDownloading {
            downloadIndicator.startAnimating()
            fileImageView.image = UIImage(systemName: "arrow.down.doc") // 下載中的圖標
        } else {
            downloadIndicator.stopAnimating()
            fileImageView.image = UIImage(systemName: "doc") // 普通文件圖標
        }
    }
}

extension FileCell: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            // 編輯文件名稱操作
            let editAction = UIAction(title: "編輯文件名稱", image: UIImage(systemName: "pencil")) { [weak self] _ in
                guard let self = self else { return }
                self.delegate?.fileCellDidRequestEditName(self)
            }
            
            // 刪除文件操作
            let deleteAction = UIAction(title: "刪除文件", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
                guard let self = self else { return }
                self.delegate?.fileCellDidRequestDelete(self)
            }
            
            // 返回包含兩個操作的菜單
            return UIMenu(title: "", children: [editAction, deleteAction])
        }
    }
}
