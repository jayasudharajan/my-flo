//
//  AmenitiesCell.swift
//  Flo
//
//  Created by Matias Paillet on 6/14/19.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal protocol AmenitiesCellDelegate: class {
    func didChangeAmenity(selected: Bool, amenity: BaseListModel, forGroup: String)
}

internal class AmenitiesCell: UITableViewCell {
    
    @IBOutlet fileprivate weak var txtOption: UILabel!
    @IBOutlet fileprivate weak var btnCheck: UIButton!
    
    public weak var delegate: AmenitiesCellDelegate?
    fileprivate var amenity: BaseListModel?
    fileprivate var group = ""
    
    override func awakeFromNib() {
        super.awakeFromNib()
        txtOption.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(checkPressed)))
        txtOption.isUserInteractionEnabled = true
    }
    
    public func configure(_ amenity: BaseListModel, isSelected: Bool, group: String) {
        self.amenity = amenity
        self.group = group
        txtOption.text = amenity.name
        self.btnCheck.isSelected = isSelected
        self.txtOption.alpha = isSelected ? 1 : 0.5
    }
    
    public func configure(option: String, isSelected: Bool) {
        txtOption.gestureRecognizers = nil
        txtOption.text = option
        self.btnCheck.isSelected = isSelected
        self.txtOption.alpha = isSelected ? 1 : 0.5
    }
    
    // MARK: Actions
    
    @IBAction fileprivate func checkPressed() {
        self.btnCheck.isSelected = !self.btnCheck.isSelected
        self.txtOption.alpha = self.btnCheck.isSelected ? 1 : 0.5
        guard let currentAmenity = self.amenity else {
            return
        }
        delegate?.didChangeAmenity(selected: self.btnCheck.isSelected, amenity: currentAmenity, forGroup: group)
    }
    
}
