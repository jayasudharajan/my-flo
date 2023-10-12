//
//  FloUIAlert.swift
//  Flo
//
//  Created by Maurice Bachelor on 7/13/16.
//  Copyright © 2016 Flo Technologies. All rights reserved.
//

import UIKit

extension UIAlertController {
    
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
    
    open override var shouldAutorotate: Bool {
        return false
    }
    
}
