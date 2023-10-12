//
//  FloDetectComparisonInfoTableViewCell.swift
//  Flo
//
//  Created by Nicolás Stefoni on 20/09/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class FloDetectComparisonInfoTableViewCell: UITableViewCell {

    @IBOutlet fileprivate var bannerView: UIView!
    @IBOutlet fileprivate var logoImageView: UIImageView!
    @IBOutlet fileprivate var logoImageViewWidth: NSLayoutConstraint!
    @IBOutlet fileprivate var infoLabel: UILabel!
    @IBOutlet fileprivate var arrowImageView: UIImageView!
    @IBOutlet fileprivate var arrowImageViewWidth: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        bannerView.layer.cornerRadius = 8
        bannerView.layer.shadowRadius = 6
        bannerView.layer.shadowOffset = CGSize(width: 0, height: 6)
        bannerView.layer.shadowOpacity = 0.3
        bannerView.layer.shadowColor = StyleHelper.colors.darkBlue.cgColor
    }
    
    public func configure(_ status: ComputationStatus) {
        if status == .notSubscribed {
            logoImageView.isHidden = false
            logoImageViewWidth.constant = 40
            infoLabel.text = "add_floprotect_to_see_your_homes_usage_by_fixture".localized
            arrowImageView.isHidden = false
            arrowImageViewWidth.constant = 12
        } else {
            logoImageView.isHidden = true
            logoImageViewWidth.constant = 0
            arrowImageView.isHidden = true
            arrowImageViewWidth.constant = 0
            
            if status == .noUsage {
                infoLabel.text = "no_fixture_data_detected_description".localized
                
            } else if status == .learning {
                infoLabel.text = "fixture_learning_description".localized
            }
        }
    }

}
