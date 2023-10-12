//
//  FloImageOptionButtonBackground.swift
//  Flo
//
//  Created by Matias Paillet on 6/19/19.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class FloImageOptionButtonBackground: UIView {
    
    @IBOutlet fileprivate weak var txtTitle: UILabel!
    @IBOutlet fileprivate weak var imgCenter: UIImageView!
    @IBOutlet fileprivate weak var imgEllipse: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    class func instanceFromNib() -> FloImageOptionButtonBackground {
        return UINib(nibName: "FloImageOptionButton", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as? FloImageOptionButtonBackground ?? FloImageOptionButtonBackground()
    }
    
    public func configure(_ text: String, centerImage: String?) {
        self.txtTitle.text = text
        if centerImage != nil {
            self.imgCenter.image = UIImage(named: centerImage!)?.withRenderingMode(.alwaysTemplate)
        }
        self.setSelected(false)
    }
    
    public func setSelected(_ selected: Bool) {
        if selected {
            self.txtTitle.textColor = StyleHelper.colors.white
            self.imgEllipse.image = UIImage(named: "ellipse_white")
            self.imgCenter.tintColor = StyleHelper.colors.white
        } else {
            self.txtTitle.textColor = StyleHelper.colors.secondaryText
            self.imgEllipse.image = UIImage(named: "ellipse_grey")
            self.imgCenter.tintColor = StyleHelper.colors.buttonIcons
        }
    }
}
