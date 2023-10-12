//
//  DeviceToPairTableViewCell.swift
//  Flo
//
//  Created by Nicolás Stefoni on 13/06/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class DeviceToPairTableViewCell: UITableViewCell {

    @IBOutlet fileprivate weak var containerView: UIView!
    @IBOutlet fileprivate weak var deviceImageView: UIImageView!
    @IBOutlet fileprivate weak var deviceLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        containerView.layer.cornerRadius = 10
    }
    
    public func configure(_ device: DeviceToPair) {
        deviceLabel.text = device.typeFriendly
        deviceImageView.image = device.image
    }

}
