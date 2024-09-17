//
//  StudentHomeVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/14.
//

import UIKit

class StudentHomeVC: UIViewController, UICollectionViewDelegateFlowLayout {

    private let viewModel = StudentHomeViewModel()
    private var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupCollectionView()
        bindViewModel()
        collectionView.backgroundColor = .white
        viewModel.fetchTeachers()
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

extension StudentHomeVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfTeachers()
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TeacherCell", for: indexPath) as? TeacherCell else {
            return UICollectionViewCell()
        }
        
        let teacher = viewModel.teacher(at: indexPath.item)
        cell.configure(with: teacher)
        cell.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.00)
        return cell
    }
}

extension StudentHomeVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedTeacher = viewModel.teacher(at: indexPath.item)
    
        let detailVC = TeacherDetailVC()
        detailVC.teacher = selectedTeacher
        
        navigationController?.pushViewController(detailVC, animated: true)
        
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}
