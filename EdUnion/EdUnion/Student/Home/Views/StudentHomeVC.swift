//
//  StudentHomeVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/14.
//

import UIKit

//class StudentHomeVC: UIViewController, UICollectionViewDelegateFlowLayout {
//
//    private let viewModel = StudentHomeViewModel()
//    private var collectionView: UICollectionView!
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        view.backgroundColor = .white
//        
//        setupCollectionView()
//        bindViewModel()
//        collectionView.backgroundColor = .white
//        viewModel.fetchTeachers()
//    }
//
//    private func bindViewModel() {
//        viewModel.onDataUpdate = { [weak self] in
//            self?.collectionView.reloadData()
//        }
//    }
//
//    private func setupCollectionView() {
//        let layout = UICollectionViewFlowLayout()
//        
//        let padding: CGFloat = 16
//        let itemsPerRow: CGFloat = 2
//        
//        let availableWidth = view.frame.width - (padding * (itemsPerRow + 1))
//        let itemWidth = availableWidth / itemsPerRow
//        
//        layout.itemSize = CGSize(width: itemWidth, height: itemWidth * 1.5)
//        
//        layout.minimumInteritemSpacing = padding
//        layout.minimumLineSpacing = padding
//        
//        layout.sectionInset = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
//        
//        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
//        collectionView.backgroundColor = .white
//        collectionView.delegate = self
//        collectionView.dataSource = self
//
//        collectionView.register(TeacherCell.self, forCellWithReuseIdentifier: "TeacherCell")
//        
//        view.addSubview(collectionView)
//    }
//}
//
//extension StudentHomeVC: UICollectionViewDataSource {
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return viewModel.numberOfTeachers()
//    }
//
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TeacherCell", for: indexPath) as? TeacherCell else {
//            return UICollectionViewCell()
//        }
//        
//        let teacher = viewModel.teacher(at: indexPath.item)
//        cell.configure(with: teacher)
//        cell.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.00)
//        return cell
//    }
//}
//
//extension StudentHomeVC: UICollectionViewDelegate {
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        let selectedTeacher = viewModel.teacher(at: indexPath.item)
//    
//        let detailVC = TeacherDetailVC()
//        detailVC.teacher = selectedTeacher
//        
//        navigationController?.pushViewController(detailVC, animated: true)
//        
//        collectionView.deselectItem(at: indexPath, animated: true)
//    }
//}
class StudentHomePageVC: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    private var pageViewController: UIPageViewController!
    
    // 三個視圖控制器：關注、發現、常用
    private let viewControllers: [UIViewController] = [FollowVC(), StudentHomePageVC(), FrequentlyUsedVC()]
    
    // 更新為三個選項
    private let segmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["關注", "發現", "常用"])
        control.selectedSegmentIndex = 1 // 預設選中「發現」
        control.backgroundColor = .white
        control.selectedSegmentTintColor = .red
        control.setTitleTextAttributes([.foregroundColor: UIColor.black], for: .selected)
        control.setTitleTextAttributes([.foregroundColor: UIColor.lightGray], for: .normal)
        return control
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSegmentedControl()
        setupPageViewController()
    }
    
    private func setupSegmentedControl() {
        segmentedControl.addTarget(self, action: #selector(segmentedControlChanged), for: .valueChanged)
        
        view.addSubview(segmentedControl)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            segmentedControl.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    @objc private func segmentedControlChanged() {
        let selectedIndex = segmentedControl.selectedSegmentIndex
        let direction: UIPageViewController.NavigationDirection = selectedIndex < pageViewController.viewControllers?.firstIndex(of: viewControllers[selectedIndex]) ?? 1 ? .reverse : .forward
        pageViewController.setViewControllers([viewControllers[selectedIndex]], direction: direction, animated: true, completion: nil)
    }
    
    private func setupPageViewController() {
        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pageViewController.delegate = self
        pageViewController.dataSource = self
        
        pageViewController.setViewControllers([viewControllers[1]], direction: .forward, animated: true, completion: nil) // 預設選中「發現」
        
        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pageViewController.view.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 8),
            pageViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        pageViewController.didMove(toParent: self)
    }
    
    // MARK: - UIPageViewControllerDataSource
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = viewControllers.firstIndex(of: viewController), index > 0 else {
            return nil
        }
        return viewControllers[index - 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = viewControllers.firstIndex(of: viewController), index < viewControllers.count - 1 else {
            return nil
        }
        return viewControllers[index + 1]
    }
    
    // MARK: - UIPageViewControllerDelegate
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed, let visibleVC = pageViewController.viewControllers?.first else { return }
        let index = viewControllers.firstIndex(of: visibleVC)!
        segmentedControl.selectedSegmentIndex = index
    }
}

class FollowVC: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .yellow  // 測試背景色
        // 這裡可以添加關注頁面的內容
    }
}

class FrequentlyUsedVC: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .green  // 測試背景色
        // 這裡可以添加常用頁面的內容
    }
}
