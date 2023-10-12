//
//  ConnectWithNewDeviceTableViewCell.swift
//  Flo
//
//  Created by Josefina Perez on 26/06/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class ConnectWithNewDeviceTableViewCell: UITableViewCell {
    
    @IBOutlet fileprivate weak var connectWithDeviceView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        connectWithDeviceView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.1)
        connectWithDeviceView.layer.addDashedBorder(withColor: UIColor(red: 1, green: 1, blue: 1, alpha: 0.2))
    }
    
}
