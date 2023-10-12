//
//  RadioButtonOptionTableViewCell.swift
//  Flo
//
//  Created by Josefina Perez on 11/07/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class RadioButtonOptionTableViewCell: UITableViewCell {
    
    @IBOutlet var lblOption: UILabel!
    @IBOutlet var imgSelected: UIImageView!
    
    public func configure(option: String, selected: Bool) {
        lblOption.text = option
        imgSelected.isHidden = !selected
    }
}
