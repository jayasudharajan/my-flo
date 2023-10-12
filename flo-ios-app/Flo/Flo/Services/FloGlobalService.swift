//
//  FloGlobalService.swift
//  Flo
//
//  Created by Maurice Bachelor on 3/16/16.
//  Copyright © 2016 Flo Technologies. All rights reserved.
//

final class FloGlobalServices {
    
    // Singleton
    static let instance = FloGlobalServices()
    
    // Instance variables
    fileprivate(set) var isConnected = {
        (UIApplication.shared.delegate as? AppDelegate)?.reachability.currentReachabilityStatus() != NotReachable
    }
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.checkForReachability(_:)), name: NSNotification.Name.reachabilityChanged, object: nil)
    }
    
    @objc func checkForReachability(_ notification: Notification) {
        if let networkReachability = notification.object as? FloApiCheck {
            let remoteHostStatus = networkReachability.currentReachabilityStatus()
            
            if remoteHostStatus.rawValue == NotReachable.rawValue {
                let noCxnAlert = UIAlertController(title: "error_popup_title".localized() + " 008",
                                                   message: "no_internet_connection_detected".localized,
                                                   preferredStyle: .alert)
                noCxnAlert.addAction(UIAlertAction(title: "ok".localized(), style: .default, handler: nil))
                UIApplication.shared.keyWindow?.rootViewController?.present(noCxnAlert, animated: true, completion: nil)
            }
        }
    }
    
}
