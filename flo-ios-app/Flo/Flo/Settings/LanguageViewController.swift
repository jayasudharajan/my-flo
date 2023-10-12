//
//  LanguageViewController.swift
//  Flo
//
//  Created by Josefina Perez on 05/07/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit
import Localize_Swift

internal class LanguageViewController: FloBaseViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet private weak var tableViewHeight: NSLayoutConstraint!
    
    private let kLanguageCellHeight: CGFloat = 50
    private var languages: [Language] {
        return LanguageHelper.getAvailableLanguages()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.layer.addGradient(from: StyleHelper.colors.darkBlue, to: StyleHelper.colors.gradient1Secondary, angle: 90)
        
        setupNavBarWithBack(andTitle: "language".localized, tint: StyleHelper.colors.white,
                            titleColor: StyleHelper.colors.white)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableViewHeight.constant = CGFloat(languages.count) * kLanguageCellHeight + 40
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    // MARK: - Overrides
    override func shouldHideNavBar() -> Bool {
        return false
    }
    
    // MARK: - Table view delegate and data source
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return languages.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let languageCell = tableView.dequeueReusableCell(withIdentifier: "language") as? LanguageTableViewCell
            else {
                return UITableViewCell()
        }
        
        languageCell.configure(language: languages[indexPath.row])
        return languageCell
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return kLanguageCellHeight
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        Localize.setCurrentLanguage(languages[indexPath.row].code)
        tableView.reloadData()
    }
}
