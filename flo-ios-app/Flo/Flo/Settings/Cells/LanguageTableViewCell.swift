//
//  LanguageTableViewCell.swift
//  Flo
//
//  Created by Josefina Perez on 05/07/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class LanguageTableViewCell: UITableViewCell {
    
    @IBOutlet fileprivate var lblLanguage: UILabel!
    @IBOutlet fileprivate var lblLanguageCode: UILabel!
    @IBOutlet fileprivate var imgSelected: UIImageView!

    public func configure(language: Language) {
        lblLanguage.text = language.name
        lblLanguageCode.text = language.abbreviation
        
        imgSelected.isHidden = !(language.code == LanguageHelper.getCurrentLanguageCode())
    }
    
}
