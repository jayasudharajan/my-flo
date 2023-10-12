//
//  AlarmsSettingHeaderTableViewCell.swift
//  Flo
//
//  Created by Josefina Perez on 31/07/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class AlertsSettingHeaderTableViewCell: UITableViewCell {

    @IBOutlet fileprivate weak var lblSeverity: UILabel!
    @IBOutlet fileprivate weak var colorView: UIView!
    
    func configure(severity: AlertSeverity) {
        lblSeverity.text = severity.name
        colorView.backgroundColor = severity.color
    }
}
