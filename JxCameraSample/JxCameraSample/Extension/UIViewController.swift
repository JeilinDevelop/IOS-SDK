//
//  UIViewController.swift
//  Polaroid
//
//  Created by jxcs on 2025/4/23.
//

import UIKit
import Toast_Swift

extension UIViewController {
        
    func showToast(_ message: String) {
        showToast(message: message, view: nil)
    }
    
    func showToast(message: String, view: UIView? = nil) {
        let view = if view == nil {
            self.view
        } else {
            view
        }
        view?.makeToast(message)
    }
    
    func getTopViewController() -> UIViewController? {
        if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
            return getTopViewController(from: rootViewController)
        }
        return nil
    }

    private func getTopViewController(from rootViewController: UIViewController) -> UIViewController? {
        if let presentedViewController = rootViewController.presentedViewController {
            return getTopViewController(from: presentedViewController)
        }
        if let navigationController = rootViewController as? UINavigationController {
            return navigationController.visibleViewController
        }
        if let tabBarController = rootViewController as? UITabBarController {
            return tabBarController.selectedViewController
        }
        return rootViewController
    }
}
