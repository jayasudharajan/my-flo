//
//  LanguageHelper.swift
//  Flo
//
//  Created by Josefina Perez on 10/07/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit
import Localize_Swift

internal struct Language {
    
    var name: String
    var abbreviation: String
    var code: String
}

internal class LanguageHelper: NSObject {
    
    fileprivate static var defaultLanguage = Language(name: "english".localized, abbreviation: "eng".localized, code: "en")
    
    fileprivate static var availableLanguages = [
        defaultLanguage,
        Language(name: "french".localized, abbreviation: "fre".localized, code: "fr"),
        Language(name: "spanish".localized, abbreviation: "esp".localized, code: "es"),
        Language(name: "chinese".localized, abbreviation: "chi".localized, code: "zh_TW")
    ]
    
    public class func getAvailableLanguages() -> [Language] {
        
        var languages = availableLanguages
        languages = languages.sorted(by: { $0.name < $1.name })
        
        return languages
    }
    
    public class func getCurrentLanguage() -> Language {
        return (availableLanguages.first(where: { $0.code == getCurrentLanguageCode()}) ?? defaultLanguage)
    }
    
    public class func getCurrentLanguageCode() -> String {
        return Localize.currentLanguage()
    }
}
