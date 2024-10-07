//
//  AllTeacherVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/22.
//

import UIKit

class AllTeacherVC: BaseCollectionVC {
    
    override func viewDidLoad() {
        self.viewModel = AllTeacherViewModel()
        super.viewDidLoad()
        setupViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.fetchData()
    }
    
    private func setupViewModel() {
        viewModel.onDataUpdate = { [weak self] in
            self?.collectionView.reloadData()
        }
        viewModel.fetchData()
    }
}
