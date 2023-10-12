//
//  FloApplication.swift
//  Flo
//
//  Created by Maurice Bachelor on 5/17/16.
//  Copyright © 2016 Flo Technologies. All rights reserved.
//

import UIKit

extension UIApplication {
    
    public class func topViewController(
        _ viewController: UIViewController? = UIApplication.shared.keyWindow?.rootViewController
    ) -> UIViewController? {
        if let nav = viewController as? UINavigationController {
            return topViewController(nav.visibleViewController)
        }
        if let tab = viewController as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(selected)
            }
        }
        if let presented = viewController?.presentedViewController {
            return topViewController(presented)
        }
        return viewController
    }
    
    public func registerForAllPushNotifications() {
        let notificationSettings = UIUserNotificationSettings( types: [.badge, .sound, .alert], categories: nil)
        UIApplication.shared.registerUserNotificationSettings(notificationSettings)
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    public func switchRootViewController(_ nextViewController: UIViewController?, animated: Bool) {
        self.keyWindow?.rootViewController = nextViewController
        self.keyWindow?.makeKeyAndVisible()
    }
    
}
