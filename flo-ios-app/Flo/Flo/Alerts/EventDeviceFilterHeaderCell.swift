//
//  EventDeviceFilterHeaderCell.swift
//  Flo
//
//  Created by Josefina Perez on 14/08/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

protocol EventDeviceFilterHeaderDelegate: class {
    func showEventDeviceFilter(actualYOffset: CGFloat)
}

import UIKit

internal class EventDeviceFilterHeaderCell: UITableViewCell {

    public weak var delegate: EventDeviceFilterHeaderDelegate?
    fileprivate var isEnabled = true
    
    @IBOutlet fileprivate weak var lblLocationNickname: UILabel!
    @IBOutlet fileprivate weak var lblDeviceNickname: UILabel!
    @IBOutlet fileprivate weak var filtersArrowImageView: UIImageView!
    
    @IBAction fileprivate func showFilters() {
        if isEnabled {
            filtersArrowImageView.image = UIImage(named: "arrow-up-white")
            delegate?.showEventDeviceFilter(actualYOffset: self.frame.origin.y + self.frame.height)
        }
    }
    
    public func configure(title: String, subtitle: String, enabled: Bool) {
        isEnabled = enabled
        
        lblLocationNickname.text = title
        lblDeviceNickname.text = subtitle
        filtersArrowImageView.image = UIImage(named: "arrow-down-white")
        filtersArrowImageView.isHidden = !isEnabled
    }
}
