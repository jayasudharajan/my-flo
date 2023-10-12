//
//  UITableViewCell.swift
//  Flo
//
//  Created by Maurice Bachelor on 6/27/16.
//  Copyright © 2016 Flo Technologies. All rights reserved.
//

import UIKit

extension UITableViewCell {
    
    class var storyboardId: String {
        return String(describing: self)
    }
    
    func removeMargins() {
        if self.responds(to: #selector(setter: UITableViewCell.separatorInset)) {
            self.separatorInset = UIEdgeInsets.zero
        }
        
        if self.responds(to: #selector(setter: UIView.preservesSuperviewLayoutMargins)) {
            self.preservesSuperviewLayoutMargins = false
        }
        
        if self.responds(to: #selector(setter: UIView.layoutMargins)) {
            self.layoutMargins = UIEdgeInsets.zero
        }
    }
    
}
