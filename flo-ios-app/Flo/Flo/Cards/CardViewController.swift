//
//  CardViewController.swift
//  Flo
//
//  Created by Nicolás Stefoni on 31/05/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class CardViewController: FloBaseViewController {
    
    private(set) var height: CGFloat = 10
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .clear
    }

    // MARK: - Instantiation
    public class func getInstance(withHeight height: CGFloat? = nil, storyboard name: String = "Cards") -> CardViewController {
        let storyboard = UIStoryboard(name: name, bundle: nil)
        
        if let cardViewController = storyboard.instantiateViewController(withIdentifier: String(describing: self)) as? CardViewController {
            if let unwrappedHeight = height {
                cardViewController.height = unwrappedHeight
            }
            
            return cardViewController
        }
        
        return CardViewController()
    }
    
    public func updateHeight(_ height: CGFloat) {
        self.height = height
    }
    
    public func updateWith(locationInfo: LocationModel) {
        // Override in subclasses
    }
    
    public func updateWith(deviceInfo: DeviceModel) {
        // Override in subclasses
    }
    
    // MARK: - Overrides
    override func shouldHideNavBar() -> Bool {
        if let floParent = parent as? FloBaseViewController {
            return floParent.shouldHideNavBar()
        }
        
        return true
    }

}
