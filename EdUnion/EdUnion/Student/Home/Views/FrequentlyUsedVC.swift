//
//  FrequentlyUsedVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/22.
//

import UIKit

class FrequentlyUsedVC: BaseCollectionVC {
    override func viewDidLoad() {
        self.viewModel = FrequentlyUsedViewModel()
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        viewModel.fetchData()
    }
}
