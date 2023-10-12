//
//  AddLocationTableViewCell.swift
//  Flo
//
//  Created by Nicolás Stefoni on 06/06/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class AddLocationTableViewCell: UITableViewCell {
    
    @IBOutlet fileprivate weak var containerView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        containerView.layer.cornerRadius = 10
        containerView.layer.addDashedBorder(withColor: UIColor(hex: "D7DDEA"))
    }

}
