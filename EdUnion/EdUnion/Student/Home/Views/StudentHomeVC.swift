//
//  StudentHomeVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/22.
//

import UIKit

class StudentHomeVC: UIViewController, UIScrollViewDelegate, UISearchBarDelegate {
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
        discoverLabel.textColor = .myBlack
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
    
    private let searchIcon: UIImageView = {
        let icon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        icon.tintColor = .myTint
        icon.isUserInteractionEnabled = true
        return icon
    }()
    
    private let searchBarView = SearchBarView()
    private var pageViewController: UIPageViewController!
    private var scrollView: UIScrollView?
    private let viewControllers: [UIViewController] = [FollowVC(), AllTeacherVC(), FrequentlyUsedVC()]
    
    private var pageViewControllerTopConstraint: NSLayoutConstraint?
    
    private var selectedIndex: Int = 1  
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .myBackground
        
        setupLabels()
        setupSearchIcon()
        setupPageViewController()
        setupScrollView()
        
        searchBarView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        
        if let tabBarController = self.tabBarController as? TabBarController {
            tabBarController.setCustomTabBarHidden(false, animated: true)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        labelsStackView.layoutIfNeeded()
        updateUnderlinePosition(to: selectedIndex, animated: false)
    }
    
    private func setupScrollView() {
        if let scrollView = pageViewController.view.subviews.compactMap({ $0 as? UIScrollView }).first {
            self.scrollView = scrollView
            scrollView.showsVerticalScrollIndicator = false
            scrollView.delegate = self
        }
    }
    
    private func setupSearchIcon() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(searchIconTapped))
        searchIcon.addGestureRecognizer(tapGesture)
        
        view.addSubview(searchIcon)
        view.addSubview(searchBarView)
        
        searchBarView.alpha = 0
        
        searchIcon.translatesAutoresizingMaskIntoConstraints = false
        searchBarView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            searchIcon.centerYAnchor.constraint(equalTo: labelsStackView.centerYAnchor),
            searchIcon.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            searchBarView.topAnchor.constraint(equalTo: underlineView.bottomAnchor, constant: 8),
            searchBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchBarView.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func searchIconTapped() {
        UIView.animate(withDuration: 0.3, animations: {
            self.searchBarView.alpha = self.searchBarView.alpha == 0 ? 1 : 0
            
            if self.searchBarView.alpha == 1 {
                self.pageViewControllerTopConstraint?.constant = 60
            } else {
                self.pageViewControllerTopConstraint?.constant = 10
            }
            
            self.view.layoutIfNeeded()
        }, completion: { _ in
            if self.searchBarView.alpha == 1 {
                self.searchBarView.focusSearchBar()
            } else {
                self.searchBarView.hideKeyboardAndCancel()
            }
        })
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetX = scrollView.contentOffset.x
        let width = scrollView.frame.width
        
        let progress = (offsetX - width) / width
        
        updateUnderlinePositionWithProgress(progress)
    }
    
    private func updateUnderlinePositionWithProgress(_ progress: CGFloat) {
        let totalLabels = labelsStackView.arrangedSubviews.count
        let currentLabelIndex = selectedIndex
        let nextLabelIndex = min(max(selectedIndex + (progress > 0 ? 1 : -1), 0), totalLabels - 1)
        
        guard let currentLabel = labelsStackView.arrangedSubviews[currentLabelIndex] as? UILabel else {
            return
        }
        
        guard let nextLabel = labelsStackView.arrangedSubviews[nextLabelIndex] as? UILabel else {
            return
        }
        
        let currentX = currentLabel.frame.origin.x
        let nextX = nextLabel.frame.origin.x
        
        let distance = nextX - currentX
        let newX = currentX + distance * abs(progress)
        
        underlineView.frame.origin.x = newX + labelsStackView.frame.origin.x
    }
    
    private func setupLabels() {
        view.addSubview(labelsStackView)
        labelsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(underlineView)
        underlineView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            labelsStackView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5),
            labelsStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            labelsStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            labelsStackView.heightAnchor.constraint(equalToConstant: 40),
            
            underlineView.topAnchor.constraint(equalTo: labelsStackView.bottomAnchor, constant: 2),
            underlineView.heightAnchor.constraint(equalToConstant: 3),
            underlineView.widthAnchor.constraint(equalToConstant: 60),
            underlineView.leadingAnchor.constraint(
                equalTo: labelsStackView.arrangedSubviews[selectedIndex].leadingAnchor
            )
        ])
        
        for (index, label) in labelsStackView.arrangedSubviews.enumerated() {
            if let label = label as? UILabel {
                label.isUserInteractionEnabled = true
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(labelTapped(_:)))
                label.addGestureRecognizer(tapGesture)
                label.tag = index
            }
        }
    }
    
    private func setupPageViewController() {
        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pageViewController.delegate = self
        pageViewController.dataSource = self
        
        pageViewController.setViewControllers([viewControllers[selectedIndex]], direction: .forward, animated: false, completion: nil)
        
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
    
    private func updateUnderlinePosition(to index: Int, animated: Bool = true) {
        let targetX = labelsStackView.arrangedSubviews[index].frame.origin.x + labelsStackView.frame.origin.x
        
        if underlineView.frame.origin.x == targetX {
            return
        }
        
        let updatePosition = {
            self.underlineView.frame.origin.x = targetX
        }
        
        if animated {
            UIView.animate(withDuration: 0.3, animations: updatePosition)
        } else {
            updatePosition()
        }
        
        for (i, label) in labelsStackView.arrangedSubviews.enumerated() {
            if let label = label as? UILabel {
                label.textColor = (i == index) ? .myBlack : .gray
            }
        }
    }
    
    @objc private func labelTapped(_ sender: UITapGestureRecognizer) {
        guard let tappedLabel = sender.view as? UILabel else { return }
        let targetIndex = tappedLabel.tag
        
        let direction: UIPageViewController.NavigationDirection = targetIndex > selectedIndex ? .forward : .reverse
        
        pageViewController.setViewControllers([viewControllers[targetIndex]], direction: direction, animated: true, completion: nil)
        
        selectedIndex = targetIndex
        updateUnderlinePosition(to: targetIndex, animated: true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let query = searchBar.text, let viewModel = getCurrentViewModel() else { return }
        viewModel.search(query: query)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard let viewModel = getCurrentViewModel() else { return }
        viewModel.search(query: searchText)
    }
    
    private func getCurrentViewModel() -> BaseCollectionViewModelProtocol? {
        if let currentVC = pageViewController.viewControllers?.first as? AllTeacherVC {
            return currentVC.viewModel
        } else if let currentVC = pageViewController.viewControllers?.first as? FollowVC {
            return currentVC.viewModel
        } else if let currentVC = pageViewController.viewControllers?.first as? FrequentlyUsedVC {
            return currentVC.viewModel
        }
        return nil
    }
}

extension StudentHomeVC: SearchBarViewDelegate {
    func searchBarView(_ searchBarView: SearchBarView, didChangeText text: String) {
        if let currentVC = pageViewController.viewControllers?.first as? AllTeacherVC {
            currentVC.viewModel.search(query: text)
        } else if let currentVC = pageViewController.viewControllers?.first as? FollowVC {
            currentVC.viewModel.search(query: text)
        } else if let currentVC = pageViewController.viewControllers?.first as? FrequentlyUsedVC {
            currentVC.viewModel.search(query: text)
        }
    }
    
    func searchBarViewDidCancel(_ searchBarView: SearchBarView) {
        searchIconTapped()
    }
}

extension StudentHomeVC: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard let index = viewControllers.firstIndex(of: viewController),
              index > 0 else {
            return nil
        }
        return viewControllers[index - 1]
    }
    
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = viewControllers.firstIndex(of: viewController),
              index < viewControllers.count - 1 else {
            return nil
        }
        return viewControllers[index + 1]
    }
    
    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool) {
        guard completed, let visibleVC = pageViewController.viewControllers?.first else { return }
        let index = viewControllers.firstIndex(of: visibleVC)!
        selectedIndex = index
        updateUnderlinePosition(to: index, animated: false)
    }
}
