//
//  UIScreen.swift
//  Polaroid
//
//  Created by jxcs on 2025/1/10.
//

import UIKit

extension UIScreen {
    // 屏幕宽度
    static var screenWidth: CGFloat {
        return UIScreen.main.bounds.width
    }
    
    // 屏幕高度
    static var screenHeight: CGFloat {
        return UIScreen.main.bounds.height
    }
    
    // 屏幕的尺寸
    static var screenSize: CGSize {
        return UIScreen.main.bounds.size
    }
}
