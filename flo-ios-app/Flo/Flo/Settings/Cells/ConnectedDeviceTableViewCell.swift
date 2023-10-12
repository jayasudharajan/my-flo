//
//  ConnectedDeviceTableViewCell.swift
//  Flo
//
//  Created by Josefina Perez on 27/06/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class ConnectedDeviceTableViewCell: UITableViewCell {

    @IBOutlet fileprivate weak var lblName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    public func updateWith(_ device: DeviceModel) {
        lblName.text = device.nickname.isEmpty ? device.type : device.nickname
    }
    
    public func updateWith(location: LocationModel) {
        lblName.text = location.nickname.isEmpty ? location.address : location.nickname
    }

}
