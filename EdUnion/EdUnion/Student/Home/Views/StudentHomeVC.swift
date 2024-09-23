//
//  StudentHomeVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/22.
//

import UIKit

class StudentHomeVC: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIScrollViewDelegate {

    private var pageViewController: UIPageViewController!
    private let viewControllers: [UIViewController] = [FollowVC(), AllTeacherVC(), FrequentlyUsedVC()]
    private var pageViewControllerTopConstraint: NSLayoutConstraint?
    
    private let searchBar: UISearchBar = {
            let searchBar = UISearchBar()
            searchBar.placeholder = "搜尋"
            searchBar.alpha = 0 // 初始設置為隱藏狀態
            return searchBar
        }()
        
        private let searchIcon: UIImageView = {
            let icon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
            icon.tintColor = .backButton
            icon.isUserInteractionEnabled = true
            return icon
        }()
    
    private let labelsStackView: UIStackView = {
        let followLabel = UILabel()
        followLabel.text = "關注"
        followLabel.textAlignment = .center
        followLabel.textColor = .gray
        followLabel.font = .systemFont(ofSize: 18, weight: .bold)
        followLabel.isUserInteractionEnabled = true
        
        let discoverLabel = UILabel()
        discoverLabel.text = "發現"
        discoverLabel.textAlignment = .center
        discoverLabel.textColor = .black
        discoverLabel.font = .systemFont(ofSize: 18, weight: .bold)
        discoverLabel.isUserInteractionEnabled = true
        
        let frequentlyUsedLabel = UILabel()
        frequentlyUsedLabel.text = "常用"
        frequentlyUsedLabel.textAlignment = .center
        frequentlyUsedLabel.textColor = .gray
        frequentlyUsedLabel.font = .systemFont(ofSize: 18, weight: .bold)
        frequentlyUsedLabel.isUserInteractionEnabled = true
        
        let stackView = UIStackView(arrangedSubviews: [followLabel, discoverLabel, frequentlyUsedLabel])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 10
        return stackView
    }()

    private let underlineView: UIView = {
        let view = UIView()
        view.backgroundColor = .mainOrange
        return view
    }()
    
    private var selectedIndex = 1
    private var scrollView: UIScrollView?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        setupLabels()
        setupPageViewController()
        setupSearchIcon()

        // 獲取 UIPageViewController 的 scrollView
        if let scrollView = pageViewController.view.subviews.compactMap({ $0 as? UIScrollView }).first {
            self.scrollView = scrollView
            scrollView.delegate = self
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    private func setupSearchIcon() {
        // 添加手勢識別器
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(searchIconTapped))
        searchIcon.addGestureRecognizer(tapGesture)

        // 將 searchIcon 和 searchBar 添加到視圖
        view.addSubview(searchIcon)
        view.addSubview(searchBar)

        // 設置 searchBar 的背景顏色和邊框
        searchBar.setBackgroundImage(UIImage(), for: .any, barMetrics: .default) // 移除默認背景圖像
        searchBar.backgroundImage = UIImage()
        searchBar.backgroundColor = .white // 設置為白色背景
        searchBar.layer.borderWidth = 0  // 設置邊框寬度
        searchBar.layer.borderColor = UIColor.clear.cgColor  // 設置邊框顏色

        searchBar.alpha = 0  // 初始狀態下隱藏

        // 設置 searchBar 和 searchIcon 的布局
        searchIcon.translatesAutoresizingMaskIntoConstraints = false
        searchBar.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            searchIcon.centerYAnchor.constraint(equalTo: labelsStackView.centerYAnchor),
            searchIcon.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // 初始時 searchBar 不可見，布局應該緊貼 labelsStackView
            searchBar.topAnchor.constraint(equalTo: underlineView.bottomAnchor, constant: 8),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchBar.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    @objc private func searchIconTapped() {
        // 切換 searchBar 的顯示狀態並更新 pageViewController 的布局
        UIView.animate(withDuration: 0.3, animations: {
            self.searchBar.alpha = self.searchBar.alpha == 0 ? 1 : 0
            
            // 更新 pageViewController 的 topAnchor 依據 searchBar 的顯示狀態
            if self.searchBar.alpha == 1 {
                self.pageViewControllerTopConstraint?.constant = 60 // 當 searchBar 顯示時推動 pageViewController
            } else {
                self.pageViewControllerTopConstraint?.constant = 10 // 當 searchBar 隱藏時恢復原位
            }

            self.view.layoutIfNeeded()
        }, completion: { _ in
            // 顯示或隱藏鍵盤
            if self.searchBar.alpha == 1 {
                self.searchBar.becomeFirstResponder()
            } else {
                self.searchBar.resignFirstResponder()
            }
        })
    }

    // 根據 searchBar 的顯示狀態來調整 pageViewController 的佈局
    private func updatePageViewControllerConstraints(isSearchBarVisible: Bool) {
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        pageViewController.view.removeConstraints(pageViewController.view.constraints)

        NSLayoutConstraint.activate([
            pageViewController.view.topAnchor.constraint(equalTo: isSearchBarVisible ? searchBar.bottomAnchor : underlineView.bottomAnchor, constant: 10),
            pageViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }


    // UIScrollViewDelegate 方法
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetX = scrollView.contentOffset.x
        let width = scrollView.frame.width
        
        // 監聽滑動，計算滑動進度
        let progress = (offsetX - width) / width
        
        // 根據滑動進度更新 underlineView 的位置
        updateUnderlinePositionWithProgress(progress)
    }

    // 根據滑動進度更新 underlineView 的位置
    private func updateUnderlinePositionWithProgress(_ progress: CGFloat) {
        // 獲取當前和下一個 Label 的索引
        let totalLabels = labelsStackView.arrangedSubviews.count
        let currentLabelIndex = selectedIndex
        let nextLabelIndex = min(max(selectedIndex + (progress > 0 ? 1 : -1), 0), totalLabels - 1)
        
        // 獲取當前和下一個 Label
        let currentLabel = labelsStackView.arrangedSubviews[currentLabelIndex] as! UILabel
        let nextLabel = labelsStackView.arrangedSubviews[nextLabelIndex] as! UILabel
        
        // 計算當前和下一個 Label 的起始 x 位置，並且相對於 labelsStackView
        let currentX = currentLabel.frame.origin.x
        let nextX = nextLabel.frame.origin.x
        
        // 計算紅色線條的新 x 位置
        let newX = currentX + (nextX - currentX) * abs(progress)
        
        // 更新紅色線條的位置 (相對於 labelsStackView，而不是螢幕的 frame)
        underlineView.frame.origin.x = newX + labelsStackView.frame.origin.x
    }


    private func setupLabels() {
        // 設置 labelsStackView 到主視圖
        view.addSubview(labelsStackView)
        labelsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // 設置下方紅色的移動線條
        view.addSubview(underlineView)
        underlineView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
                // 設置 labelsStackView 的寬度為螢幕寬度的一半，並讓它水平居中
                labelsStackView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5),
                labelsStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                labelsStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),  // 水平居中
                labelsStackView.heightAnchor.constraint(equalToConstant: 40),
                
                // 設置下方紅色線條的位置和寬度
                underlineView.topAnchor.constraint(equalTo: labelsStackView.bottomAnchor, constant: 2),
                underlineView.heightAnchor.constraint(equalToConstant: 3),
                underlineView.widthAnchor.constraint(equalToConstant: 60),  // 固定紅色線條寬度
                underlineView.leadingAnchor.constraint(equalTo: labelsStackView.arrangedSubviews[selectedIndex].leadingAnchor)
        ])
        
        for (index, label) in labelsStackView.arrangedSubviews.enumerated() {
            if let label = label as? UILabel {
                label.isUserInteractionEnabled = true
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(labelTapped(_:)))
                label.addGestureRecognizer(tapGesture)
                label.tag = index  // 使用 tag 保存索引
            }
        }
    }

    private func setupPageViewController() {
        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pageViewController.delegate = self
        pageViewController.dataSource = self

        // 設置初始頁面
        pageViewController.setViewControllers([viewControllers[selectedIndex]], direction: .forward, animated: true, completion: nil)

        addChild(pageViewController)
        view.addSubview(pageViewController.view)

        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        pageViewControllerTopConstraint = pageViewController.view.topAnchor.constraint(equalTo: underlineView.bottomAnchor, constant: 10)

        NSLayoutConstraint.activate([
            pageViewControllerTopConstraint!,
            pageViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        pageViewController.didMove(toParent: self)
    }

    // MARK: - UIPageViewControllerDataSource 和 Delegate

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = viewControllers.firstIndex(of: viewController), index > 0 else { return nil }
        return viewControllers[index - 1]
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = viewControllers.firstIndex(of: viewController), index < viewControllers.count - 1 else { return nil }
        return viewControllers[index + 1]
    }

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed, let visibleVC = pageViewController.viewControllers?.first else { return }
        let index = viewControllers.firstIndex(of: visibleVC)!
        updateUnderlinePosition(to: index)
        selectedIndex = index
    }

    private func updateUnderlinePosition(to index: Int) {
        UIView.animate(withDuration: 0.3) {
            // 更新紅色線條的最終位置，並且相對於 labelsStackView
            self.underlineView.frame.origin.x = self.labelsStackView.arrangedSubviews[index].frame.origin.x + self.labelsStackView.frame.origin.x
        }

        // 更新標籤顏色
        for (i, label) in labelsStackView.arrangedSubviews.enumerated() {
            if let label = label as? UILabel {
                label.textColor = (i == index) ? .black : .gray
            }
        }
    }
    

    
    @objc private func labelTapped(_ sender: UITapGestureRecognizer) {
        guard let tappedLabel = sender.view as? UILabel else { return }
        let targetIndex = tappedLabel.tag

        let direction: UIPageViewController.NavigationDirection = targetIndex > selectedIndex ? .forward : .reverse
            
            // 使用 completion handler 來確保動畫完成後執行更新操作
            pageViewController.setViewControllers([viewControllers[targetIndex]], direction: direction, animated: true) { [weak self] completed in
                guard completed else { return }  // 如果動畫沒有完成，退出

                // 更新選中的頁面索引
                self?.selectedIndex = targetIndex
                
                // 確保動畫結束後再更新下方的紅色線條位置
                self?.updateUnderlinePosition(to: targetIndex)
            }
        // 只在不同頁面時切換
//        if targetIndex != selectedIndex {
//            let direction: UIPageViewController.NavigationDirection = targetIndex > selectedIndex ? .forward : .reverse
//            pageViewController.setViewControllers([viewControllers[targetIndex]], direction: direction, animated: true, completion: nil)
//            selectedIndex = targetIndex
//            updateUnderlinePosition(to: selectedIndex)
//        }
    }
}
