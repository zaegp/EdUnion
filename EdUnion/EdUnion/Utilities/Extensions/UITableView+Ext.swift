//
//  UITableView+Ext.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/10/18.
//

import UIKit

extension UITableView {
    func dequeueReusableCell<T: UITableViewCell>(withIdentifier identifier: String, for indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? T else {
            fatalError("Unable to dequeue cell with identifier: \(identifier)")
        }
        return cell
    }
}
