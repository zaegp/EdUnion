//
//  FollowVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/21.
//

import UIKit

class FollowVC: BaseCollectionVC {
    
    override func viewDidLoad() {
        // 設置 ViewModel 為 FollowViewModel
        self.viewModel = FollowViewModel()
        super.viewDidLoad()
    }
}
