//
//  StudentHomeVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/14.
//

import UIKit

class StudentHomeVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    private let viewModel = StudentHomeViewModel()
    private var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
//        title = "Booking"
        
        setupCollectionView()
        bindViewModel()
        collectionView.backgroundColor = .white
        viewModel.fetchTeachers()
    }

    // 綁定 ViewModel 的數據更新
    private func bindViewModel() {
        viewModel.onDataUpdate = { [weak self] in
            self?.collectionView.reloadData()
        }
    }

    // 初始化 UICollectionView
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        
        let padding: CGFloat = 16  // 每個卡片之間的間距
        let itemsPerRow: CGFloat = 2  // 每行顯示兩個項目
        
        // 計算每個項目的寬度（去除左右間距和項目間的間隔）
        let availableWidth = view.frame.width - (padding * (itemsPerRow + 1))
        let itemWidth = availableWidth / itemsPerRow
        
        // 設置 item 的寬度和高度
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth * 1.5)
        
        layout.minimumInteritemSpacing = padding
        layout.minimumLineSpacing = padding
        
        layout.sectionInset = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        collectionView.delegate = self
        collectionView.dataSource = self

        // 註冊 Cell
        collectionView.register(TeacherCell.self, forCellWithReuseIdentifier: "TeacherCell")
        
        view.addSubview(collectionView)
    }

    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfTeachers()
//        return 10
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TeacherCell", for: indexPath) as! TeacherCell
        let teacher = viewModel.teacher(at: indexPath.item)
        cell.configure(with: teacher)
        cell.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.00)
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension StudentHomeVC: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 获取选中的 teacher 数据
        let selectedTeacher = viewModel.teacher(at: indexPath.item)
    
        let detailVC = TeacherDetailVC()
        detailVC.teacher = selectedTeacher
        
        navigationController?.pushViewController(detailVC, animated: true)
        
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}
