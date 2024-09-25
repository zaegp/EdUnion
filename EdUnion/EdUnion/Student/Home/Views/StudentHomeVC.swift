//
//  StudentHomeVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/22.
//

import UIKit

class StudentHomeVC: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIScrollViewDelegate, UISearchBarDelegate {

    private var pageViewController: UIPageViewController!
    private let viewControllers: [UIViewController] = [FollowVC(), AllTeacherVC(), FrequentlyUsedVC()]
    private var pageViewControllerTopConstraint: NSLayoutConstraint?
    
    private let searchBar: UISearchBar = {
            let searchBar = UISearchBar()
            searchBar.placeholder = "搜尋"
            searchBar.alpha = 0
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
    
    private var selectedIndex: Int?
    private var scrollView: UIScrollView?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        searchBar.delegate = self

        selectedIndex = 1

        setupLabels()
        setupPageViewController()
        setupSearchIcon()
        
        if let scrollView = pageViewController.view.subviews.compactMap({ $0 as? UIScrollView }).first {
            self.scrollView = scrollView
            scrollView.delegate = self
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        labelsStackView.layoutIfNeeded()
        updateUnderlinePosition(to: selectedIndex!)
    }
        
    private func setupSearchIcon() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(searchIconTapped))
        searchIcon.addGestureRecognizer(tapGesture)

        view.addSubview(searchIcon)
        view.addSubview(searchBar)

        searchBar.setBackgroundImage(UIImage(), for: .any, barMetrics: .default)
        searchBar.backgroundImage = UIImage()
        searchBar.backgroundColor = .white
        searchBar.layer.borderWidth = 0
        searchBar.layer.borderColor = UIColor.clear.cgColor

        searchBar.alpha = 0


        searchIcon.translatesAutoresizingMaskIntoConstraints = false
        searchBar.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            searchIcon.centerYAnchor.constraint(equalTo: labelsStackView.centerYAnchor),
            searchIcon.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            searchBar.topAnchor.constraint(equalTo: underlineView.bottomAnchor, constant: 8),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchBar.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    @objc private func searchIconTapped() {
        UIView.animate(withDuration: 0.3, animations: {
            self.searchBar.alpha = self.searchBar.alpha == 0 ? 1 : 0
            
            if self.searchBar.alpha == 1 {
                self.pageViewControllerTopConstraint?.constant = 60
            } else {
                self.pageViewControllerTopConstraint?.constant = 10
            }

            self.view.layoutIfNeeded()
        }, completion: { _ in
            if self.searchBar.alpha == 1 {
                self.searchBar.becomeFirstResponder()
            } else {
                self.searchBar.resignFirstResponder()
            }
        })
        
        self.updateUnderlinePosition(to: self.selectedIndex!)
    }

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

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetX = scrollView.contentOffset.x
        let width = scrollView.frame.width
        
        let progress = (offsetX - width) / width
   
        updateUnderlinePositionWithProgress(progress)
    }

    private func updateUnderlinePositionWithProgress(_ progress: CGFloat) {
        let totalLabels = labelsStackView.arrangedSubviews.count
        let currentLabelIndex = selectedIndex
        let nextLabelIndex = min(max(selectedIndex! + (progress > 0 ? 1 : -1), 0), totalLabels - 1)
        
        let currentLabel = labelsStackView.arrangedSubviews[currentLabelIndex!] as! UILabel
        let nextLabel = labelsStackView.arrangedSubviews[nextLabelIndex] as! UILabel
        
        let currentX = currentLabel.frame.origin.x
        let nextX = nextLabel.frame.origin.x
        
        let newX = currentX + (nextX - currentX) * abs(progress)
        
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
                underlineView.leadingAnchor.constraint(equalTo: labelsStackView.arrangedSubviews[selectedIndex!].leadingAnchor)
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

        pageViewController.setViewControllers([viewControllers[selectedIndex!]], direction: .forward, animated: true, completion: nil)

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
            self.underlineView.frame.origin.x = self.labelsStackView.arrangedSubviews[index].frame.origin.x + self.labelsStackView.frame.origin.x
        }

        for (i, label) in labelsStackView.arrangedSubviews.enumerated() {
            if let label = label as? UILabel {
                label.textColor = (i == index) ? .black : .gray
            }
        }
    }
    
    @objc private func labelTapped(_ sender: UITapGestureRecognizer) {
        guard let tappedLabel = sender.view as? UILabel else { return }
        let targetIndex = tappedLabel.tag

        let direction: UIPageViewController.NavigationDirection = targetIndex > selectedIndex! ? .forward : .reverse
            
            pageViewController.setViewControllers([viewControllers[targetIndex]], direction: direction, animated: true) { [weak self] completed in
                guard completed else { return }  

                self?.selectedIndex = targetIndex
                
                self?.updateUnderlinePosition(to: targetIndex)
            }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let query = searchBar.text else { return }

        // 根據當前的頁面來觸發相應的搜尋邏輯
        if let currentVC = pageViewController.viewControllers?.first as? AllTeacherVC {
            currentVC.viewModel.search(query: query)
        } else if let currentVC = pageViewController.viewControllers?.first as? FollowVC {
            currentVC.viewModel.search(query: query)
        } else if let currentVC = pageViewController.viewControllers?.first as? FrequentlyUsedVC {
            currentVC.viewModel.search(query: query)
        }
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // 實時搜尋
        if let currentVC = pageViewController.viewControllers?.first as? AllTeacherVC {
            currentVC.viewModel.search(query: searchText)
        } else if let currentVC = pageViewController.viewControllers?.first as? FollowVC {
            currentVC.viewModel.search(query: searchText)
        } else if let currentVC = pageViewController.viewControllers?.first as? FrequentlyUsedVC {
            currentVC.viewModel.search(query: searchText)
        }
    }
}
