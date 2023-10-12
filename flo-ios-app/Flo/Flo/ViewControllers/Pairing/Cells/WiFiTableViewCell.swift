//
//  WiFiTableViewCell.swift
//  Flo
//
//  Created by Nicolás Stefoni on 20/06/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class WiFiTableViewCell: UITableViewCell {
    
    @IBOutlet fileprivate weak var containerView: UIView!
    @IBOutlet fileprivate weak var wiFiLabel: UILabel!
    @IBOutlet fileprivate weak var wiFiHintLabel: UILabel!
    @IBOutlet fileprivate weak var wiFiImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        containerView.layer.cornerRadius = 10
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowColor = StyleHelper.colors.black.cgColor
        containerView.layer.shadowRadius = 4
        containerView.layer.shadowOpacity = 0.1
        
        wiFiImageView.tintColor = StyleHelper.colors.darkBlue
    }
    
    public func configure(_ wiFi: WiFiModel) {
        containerView.backgroundColor = wiFi.encryption == "none" ? StyleHelper.colors.lightGray : .white
        wiFiLabel.text = wiFi.ssid
        wiFiImageView.image = UIImage(named: "wifi-level\(wiFi.signalLevel)-icon")?.withRenderingMode(.alwaysTemplate)
        wiFiHintLabel.text = wiFi.signalLevel == 1 ? "not_recommended_low_strength".localized : ""
    }

}
