//
//  BaseCollectionVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/22.
//

import UIKit

protocol BaseCollectionViewModelProtocol {
    var items: [Teacher] { get set }
    var onDataUpdate: (() -> Void)? { get set }

    func fetchData()
    func numberOfItems() -> Int
    func item(at index: Int) -> Teacher
    
    func search(query: String)
}

class BaseCollectionVC: UIViewController, UICollectionViewDelegateFlowLayout {

    var collectionView: UICollectionView!
    
    var viewModel: BaseCollectionViewModelProtocol!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupCollectionView()
        bindViewModel()
        collectionView.backgroundColor = .white
        viewModel.fetchData()
    }

    private func bindViewModel() {
        viewModel.onDataUpdate = { [weak self] in
            self?.collectionView.reloadData()
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
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        collectionView.delegate = self
        collectionView.dataSource = self

        collectionView.register(TeacherCell.self, forCellWithReuseIdentifier: "TeacherCell")
        
        view.addSubview(collectionView)
    }
}

// MARK: - UICollectionViewDataSource
extension BaseCollectionVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfItems()
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TeacherCell", for: indexPath) as? TeacherCell else {
            return UICollectionViewCell()
        }
        
        let item = viewModel.item(at: indexPath.item)
        cell.configure(with: item)
        cell.contentView.layer.cornerRadius = 30
            cell.contentView.layer.borderWidth = 1.0
            cell.contentView.layer.borderColor = UIColor.clear.cgColor
            cell.contentView.layer.masksToBounds = false
        cell.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.00)
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


