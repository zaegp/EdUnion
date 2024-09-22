//
//  AllTeacherVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/22.
//

import UIKit

class AllTeacherVC: BaseCollectionVC {
    
    override func viewDidLoad() {
        self.viewModel = AllTeacherViewModel()  // 使用 StudentHomeViewModel
        super.viewDidLoad()
    }
}
