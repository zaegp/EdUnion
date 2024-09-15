//
//  UIColor+HexConvert.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/14.
//

import UIKit

extension UIColor {
    // Convert UIColor to Hex String
    var hexString: String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        self.getRed(&red, green: &green, blue: &blue, alpha: nil)
        let rgb:Int = (Int)(red*255)<<16 | (Int)(green*255)<<8 | Int(blue*255)
        return String(format:"#%06X", rgb)
    }
    
    // Initialize UIColor from Hex String
    convenience init(hexString: String) {
        var cString:String = hexString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if (cString.hasPrefix("#")) { cString.removeFirst() }
        if ((cString.count) != 6) {
            self.init(white: 1.0, alpha: 1.0)
        } else {
            var rgbValue:UInt64 = 0
            Scanner(string: cString).scanHexInt64(&rgbValue)
            self.init(
                red: CGFloat((rgbValue & 0xFF0000) >> 16)/255.0,
                green: CGFloat((rgbValue & 0x00FF00) >> 8)/255.0,
                blue: CGFloat(rgbValue & 0x0000FF)/255.0,
                alpha: CGFloat(1.0)
            )
        }
    }
}

