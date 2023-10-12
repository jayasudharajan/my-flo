//
//  UICollectionViewCell+Utils.swift
//  Flo
//
//  Created by Nicolás Stefoni on 10/06/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

extension UICollectionViewCell {
    
    class var storyboardId: String {
        return String(describing: self)
    }
    
}
