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
        view.backgroundColor = .myBackground
        
        setupCollectionView()
        bindViewModel()
        viewModel.fetchData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        collectionView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height - 80)

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
        
        collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height - 80), collectionViewLayout: layout)
        collectionView.backgroundColor = .myBackground
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
        guard indexPath.row < viewModel.numberOfItems() else {
                    print("Index out of bounds. Total items: \(viewModel.numberOfItems()), requested index: \(indexPath.row)")
                    return UICollectionViewCell()
                }
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TeacherCell", for: indexPath) as? TeacherCell else {
            return UICollectionViewCell()
        }
        
        guard indexPath.row < viewModel.numberOfItems() else { return cell }
        
        let item = viewModel.item(at: indexPath.item)
        cell.configure(with: item)
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
