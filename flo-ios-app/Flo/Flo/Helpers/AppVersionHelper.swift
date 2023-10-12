//
//  AppVersionHelper.swift
//  Flo
//
//  Created by Nicolás Stefoni on 17/10/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import Foundation

internal class AppVersionHelper {
    
    public class func validate() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            checkIfNeedsUpdate { (needsUpdate) in
                if needsUpdate {
                    showNeedsUpdatePopup()
                }
            }
        }
    }
    
    public class func checkIfNeedsUpdate(_ callback: @escaping (Bool) -> Void) {
        FloApiRequest(
            controller: "https://client-config.meetflo.com",
            method: .get,
            queryString: nil,
            data: nil,
            usingBaseUrl: false,
            done: { (_, data) in
                if let dict = data as? NSDictionary, let iosAppDict = dict["iosApp"] as? NSDictionary, let minVersion = iosAppDict["minVersion"] as? String {
                    let needsUpdate = minVersion.compare(Bundle.main.versionNumber, options: .numeric) == .orderedDescending
                    callback(needsUpdate)
                } else {
                    callback(false)
                }
            }
        ).unsecureFloRequest()
    }
    
    public class func showNeedsUpdatePopup() {
        if let rootViewController = UIApplication.shared.keyWindow?.rootViewController {
            let title = "New Version Available"
            let description = "A new app update is available. Please update your app to the latest version."
            let buttonTitle = "Update Now"
            
            let tabBarController = rootViewController as? TabBarController
            let tabController = tabBarController?.viewControllers?[tabBarController?.selectedIndex ?? 0]
            var navController = tabController as? UINavigationController
            navController = navController ?? rootViewController as? UINavigationController
            var floBaseController = navController?.viewControllers.last as? FloBaseViewController
            floBaseController = floBaseController ?? rootViewController as? FloBaseViewController
            
            if let controller = floBaseController {
                controller.showPopup(
                    title: title,
                    description: description,
                    options: [AlertPopupOption(title: buttonTitle, type: .normal, action: { openAppStore() })]
                )
            } else {
                let alertController = UIAlertController(
                    title: title,
                    message: description,
                    preferredStyle: .alert
                )
                alertController.addAction(UIAlertAction(title: buttonTitle, style: .default, handler: { _ in
                    openAppStore()
                }))
                rootViewController.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    fileprivate class func openAppStore() {
        if let url = URL(string: "itms-apps://itunes.apple.com/app/id1114650234"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.openURL(url)
        } else if let url = URL(string: "itms://itunes.apple.com/app/id1114650234"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.openURL(url)
        }
    }
}
