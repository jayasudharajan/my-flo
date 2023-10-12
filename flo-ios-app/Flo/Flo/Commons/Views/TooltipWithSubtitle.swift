//
//  TooltipWithSubtitle.swift
//  Flo
//
//  Created by Josefina Perez on 07/08/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class TooltipWithSubtitle: UIView {
    
    @IBOutlet fileprivate weak var lblTitle: UILabel!
    @IBOutlet fileprivate weak var lblSubtitle: UILabel!

    class func instanceFromNib() -> TooltipWithSubtitle {
        return UINib(nibName: "TooltipWithSubtitle", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as? TooltipWithSubtitle ?? TooltipWithSubtitle()
    }
    
    public func configure(title: String, subtitle: String) {
        lblTitle.text = title
        lblSubtitle.text = subtitle
    }
}
