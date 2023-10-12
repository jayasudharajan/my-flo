//
//  TabBarController.swift
//  Flo
//
//  Created by Nicolás Stefoni on 30/05/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class TabBarController: UITabBarController, UITabBarControllerDelegate {
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        delegate = self
        
        tabBar.backgroundImage = UIImage()
        
        for item in tabBar.items ?? [] {
            item.image = item.image?.withRenderingMode(.alwaysOriginal)
            item.selectedImage = item.selectedImage?.withRenderingMode(.alwaysOriginal)
        }
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if viewController.restorationIdentifier == "SettingsNavigationController" {
            
            if LocationsManager.shared.locations.count == 0 {
                // Do nothing for now
                return false
            }
        }
        
        return true
    }
}

extension UITabBar {
    
    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        var newSize = super.sizeThatFits(size)
        newSize.height = (UIApplication.shared.keyWindow?.layoutMargins.bottom ?? 0) + 50
        
        return newSize
    }
    
}
