//
//  UIImageView+LoadImage.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/13.
//

import UIKit

extension UIImageView {
    func loadImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            // 確保無錯誤且有返回的資料
            if let data = data, error == nil, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    // 更新圖片到主線程
                    self?.image = image
                }
            }
        }.resume()  // 開始下載任務
    }
}
