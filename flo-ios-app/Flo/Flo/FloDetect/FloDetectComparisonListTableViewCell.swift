//
//  FloDetectComparisonListTableViewCell.swift
//  Flo
//
//  Created by Juan Pablo on 09/09/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class FloDetectComparisonListTableViewCell: UITableViewCell {
    
    @IBOutlet fileprivate weak var fixtureBackgroundView: UIView!
    @IBOutlet fileprivate weak var fixtureImageView: UIImageView!
    @IBOutlet fileprivate weak var fixtureNameLabel: UILabel!
    @IBOutlet fileprivate weak var consumptionLabel: UILabel!
    @IBOutlet fileprivate weak var consumptionContainerView: UIView!
    @IBOutlet fileprivate weak var consumptionView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        fixtureBackgroundView.layer.cornerRadius = fixtureBackgroundView.frame.height / 2
        fixtureImageView.tintColor = .white
        consumptionContainerView.layer.cornerRadius = consumptionContainerView.frame.height / 2
        consumptionView.layer.cornerRadius = consumptionView.frame.height / 2
    }
    
    public func configure(_ fixture: FixtureModel, status: ComputationStatus) {
        contentView.alpha = status == .executed ? 1 : 0.3
        
        fixtureBackgroundView.backgroundColor = fixture.type.color
        fixtureImageView.image = fixture.type.image
        fixtureImageView.tintColor = StyleHelper.colors.white
        fixtureNameLabel.text = fixture.type.name
        consumptionLabel.textColor = .black
        
        var width = consumptionContainerView.frame.height
        if status == .learning || status == .noUsage {
            consumptionLabel.text = status == .learning ? "learning_with_dots".localized : "no_data".localized
        } else {
            width = consumptionContainerView.frame.width * CGFloat(fixture.ratio)
            consumptionLabel.text = String(format: "%.1f \(MeasuresHelper.unitAbbreviation(for: .volume))", fixture.consumption)
        }
        consumptionView.frame.size = CGSize(width: width, height: consumptionContainerView.frame.height)
        
        for layer in consumptionView.layer.sublayers ?? [] where layer is FloGradientLayer {
            layer.removeFromSuperlayer()
        }
        consumptionView.layer.addGradient(from: UIColor(hex: "67EFFC"), to: UIColor(hex: "2FE3F4"), angle: 0)
    }
    
}
