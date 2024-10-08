//
//  FollowVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/21.
//

import UIKit

class FollowVC: BaseCollectionVC {
    
    override func viewDidLoad() {
        self.viewModel = FollowViewModel()
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.fetchData()
    }
}
