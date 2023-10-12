//
//  RatingHelper.swift
//  Flo
//
//  Created by Nicolás Stefoni on 16/04/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import Foundation
import StoreKit

internal class RatingHelper {
    
    fileprivate static let lastRatingKey = "LAST_RATE_REQ"
    
    public class func askForRating() {
        let nowInterval = Date().timeIntervalSince1970
        let timeInterval: Double = UserDefaults.standard.double(forKey: RatingHelper.lastRatingKey)
        
        if nowInterval - timeInterval > 1209600 {
            UserDefaults.standard.set(nowInterval, forKey: RatingHelper.lastRatingKey)
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
                if #available(iOS 10.3, *) {
                    SKStoreReviewController.requestReview()
                } else {
                    if let viewController = UIApplication.shared.keyWindow?.rootViewController {
                        let alert = UIAlertController(title: "Rate us", message: "Do you like Flo?", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Rate", style: .default, handler: { _ in
                            if let writeReviewURL = URL(string: "itms-apps://itunes.apple.com/app/id1114650234"), UIApplication.shared.canOpenURL(writeReviewURL) {
                                UIApplication.shared.openURL(writeReviewURL)
                            } else if let writeReviewURL = URL(string: "itms://itunes.apple.com/app/id1114650234"), UIApplication.shared.canOpenURL(writeReviewURL) {
                                UIApplication.shared.openURL(writeReviewURL)
                            }
                        }))
                        alert.addAction(UIAlertAction(title: "Not now", style: .cancel, handler: nil))
                        
                        viewController.present(alert, animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    public class func cleanTimer() {
        UserDefaults.standard.removeObject(forKey: RatingHelper.lastRatingKey)
    }
    
}
