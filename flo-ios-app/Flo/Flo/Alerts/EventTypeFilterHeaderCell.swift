//
//  EventTypeFilterHeaderCell.swift
//  Flo
//
//  Created by Josefina Perez on 12/08/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

protocol EventTypeFilterHeaderDelegate: class {
    func showEventTypeFilter(actualYOffset: CGFloat)
}

import UIKit

internal class EventTypeFilterHeaderCell: UITableViewCell {
    
    public weak var delegate: EventTypeFilterHeaderDelegate?
    
    @IBOutlet fileprivate weak var lblLogCount: UILabel!
    @IBOutlet fileprivate weak var filtersArrowImageView: UIImageView!
    
    @IBAction fileprivate func showFilters() {
        filtersArrowImageView.image = UIImage(named: "arrow-up-white")
        delegate?.showEventTypeFilter(actualYOffset: self.frame.origin.y + self.frame.height)
    }
    
    public func configure(logCount: Int) {
        lblLogCount.text = "activity_log".localized + " (\(logCount))"
        filtersArrowImageView.image = UIImage(named: "arrow-down-white")
    }

}
