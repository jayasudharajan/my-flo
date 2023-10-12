//
//  FloDetectComparisonHeaderView.swift
//  Flo
//
//  Created by Juan Pablo on 09/09/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

struct FloDetectHeaderModel {
    
    let title: String
}

class FloDetectHeaderView: UITableViewCell {
    
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var rightLabel: UILabel!
    @IBOutlet fileprivate weak var rightImage: UIImageView!
    @IBOutlet fileprivate weak var rangeSelector: FloSelector!

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setup(_ model: FloDetectHeaderModel) {
        titleLabel.text = model.title
        rangeSelector.setStyle(.secondary)
        rangeSelector.setOptions(["today".localized, "week".localized])
        rangeSelector.selectOptionWithoutTriggers(0)
        //rangeSelector.delegate = self
    }
}
