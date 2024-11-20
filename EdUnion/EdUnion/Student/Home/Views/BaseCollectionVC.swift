//
//  BaseCollectionVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/22.
//

import UIKit

class BaseCollectionVC: UIViewController, UICollectionViewDelegateFlowLayout {
    
    var collectionView: UICollectionView!
    var viewModel: BaseCollectionViewModelProtocol!
    private var emptyStateLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .myBackground
        
        setupCollectionView()
        setupEmptyStateLabel()
        bindViewModel()
        viewModel.fetchData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        collectionView.isUserInteractionEnabled = false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        collectionView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height - 80)
        emptyStateLabel.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 50)
        emptyStateLabel.center = CGPoint(x: view.center.x, y: view.center.y - 60)
    }
    
    private func bindViewModel() {
        viewModel.onDataUpdate = { [weak self] in
            self?.collectionView.reloadData()
            self?.updateEmptyState()
        }
    }
    
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        let padding: CGFloat = 16
        let itemsPerRow: CGFloat = 2
        let availableWidth = view.frame.width - (padding * (itemsPerRow + 1))
        let itemWidth = availableWidth / itemsPerRow
        
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth * 1.5)
        layout.minimumInteritemSpacing = padding
        layout.minimumLineSpacing = padding
        layout.sectionInset = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .myBackground
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(TeacherCell.self, forCellWithReuseIdentifier: "TeacherCell")
        
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -80)
        ])
    }
    
    private func setupEmptyStateLabel() {
        emptyStateLabel = UILabel()
        emptyStateLabel.text = "還沒有關注的老師"
        emptyStateLabel.textColor = .myGray
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        emptyStateLabel.isHidden = true
        
        view.addSubview(emptyStateLabel)
    }
    
    private func updateEmptyState() {
        emptyStateLabel.isHidden = viewModel.numberOfItems() != 0
        collectionView.isHidden = viewModel.numberOfItems() == 0
    }
}

// MARK: - UICollectionViewDataSource
extension BaseCollectionVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.isLoading ? 6 : viewModel.numberOfItems() 
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TeacherCell", for: indexPath) as? TeacherCell else {
            return UICollectionViewCell()
        }
        
        if viewModel.isLoading {
            cell.isSkeleton = true
        } else {
            collectionView.isUserInteractionEnabled = true
            cell.isSkeleton = false
            let item = viewModel.item(at: indexPath.item)
            cell.configure(with: item)
        }
        
        cell.contentView.layer.cornerRadius = 30
        cell.contentView.layer.borderWidth = 1.0
        cell.contentView.layer.borderColor = UIColor.myGray.cgColor
        cell.contentView.layer.masksToBounds = false
        cell.backgroundColor = .clear
        return cell
    }
}

extension BaseCollectionVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedItem = viewModel.item(at: indexPath.item)
        
        let detailVC = TeacherDetailVC()
        detailVC.teacher = selectedItem
        
        navigationController?.pushViewController(detailVC, animated: true)
        
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}
