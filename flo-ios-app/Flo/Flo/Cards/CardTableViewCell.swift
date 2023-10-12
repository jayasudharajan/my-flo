//
//  CardTableViewCell.swift
//  Flo
//
//  Created by Nicolás Stefoni on 31/05/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class CardTableViewCell: UITableViewCell {
    
    fileprivate weak var parentViewController: UIViewController?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        contentView.preservesSuperviewLayoutMargins = false
        isMultipleTouchEnabled = false
        backgroundColor = .clear
        selectionStyle = .none
    }
    
}
