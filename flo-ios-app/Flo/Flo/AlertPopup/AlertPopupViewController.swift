//
//  AlertPopupViewController.swift
//  Flo
//
//  Created by Nicolás Stefoni on 24/05/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class AlertPopupViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    fileprivate var alertTitle = "Flo"
    fileprivate var alertDescription: String?
    fileprivate var options: [AlertPopupOption] = []
    fileprivate var headerInterface: AlertPopupHeaderProtocol?
    
    @IBOutlet fileprivate weak var containerView: UIView!
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var descriptionLabel: UILabel!
    @IBOutlet fileprivate weak var optionsTableView: UITableView!
    @IBOutlet fileprivate weak var optionsTableHeight: NSLayoutConstraint!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        containerView.layer.cornerRadius = 20
        containerView.layer.shadowColor = StyleHelper.colors.black.cgColor
        containerView.layer.shadowOffset = .zero
        containerView.layer.shadowOpacity = 0.1
        containerView.layer.shadowRadius = 8
        
        titleLabel.text = alertTitle
        descriptionLabel.text = alertDescription
        
        // Background blur effect
        let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        blurEffectView.frame = view.frame
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(blurEffectView)
        view.sendSubviewToBack(blurEffectView)
        
        // Constraints adjustment
        let maxHeight = (view.frame.height / 2) * 3 // UI design statement
        var newHeight = CGFloat(options.count) * 46
        
        if let headerView = headerInterface as? UIView {
            newHeight += headerView.frame.height
        }
        
        if newHeight > maxHeight {
            optionsTableView.clipsToBounds = true
            newHeight = maxHeight
        } else {
            optionsTableView.isScrollEnabled = false
        }
        optionsTableHeight.constant = newHeight
        
        descriptionLabel.isHidden = (descriptionLabel.text ?? "").isEmpty
    }
    
    // MARK: - Instantiation
    public class func getInstance(title: String, description: String? = nil) -> AlertPopupViewController {
        let storyboard = UIStoryboard(name: "Common", bundle: nil)
        
        if let alertPopup = storyboard.instantiateViewController(withIdentifier: AlertPopupViewController.storyboardId) as? AlertPopupViewController {
            alertPopup.alertTitle = title
            alertPopup.alertDescription = description
            
            return alertPopup
        }
        
        return AlertPopupViewController()
    }
    
    // MARK: - Add header management
    public func addHeader(_ header: AlertPopupHeaderProtocol) {
        headerInterface = header
    }
    
    // MARK: - Options management
    public func addOption(_ option: AlertPopupOption) {
        options.append(option)
    }
    
    // MARK: - Table view protocol methods
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let headerView = headerInterface as? UIView {
            return headerView
        }
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if let headerView = headerInterface as? UIView {
            return headerView.frame.height
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: AlertPopupOptionTableViewCell.storyboardId) as? AlertPopupOptionTableViewCell {
            cell.configure(options[indexPath.row])
            
            return cell
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if options[indexPath.row].type == .cancel || headerInterface == nil || headerInterface?.allowsDismiss() == true {
            DispatchQueue.main.async {
                self.dismiss(animated: true, completion: {
                    self.options[indexPath.row].action?()
                })
            }
        }
    }
    
}

// MARK: - Alert popup option model
internal enum AlertPopupOptionType {
    case normal, cancel
}

internal class AlertPopupOption {
    
    fileprivate(set) var title: String
    fileprivate(set) var type: AlertPopupOptionType
    fileprivate(set) var action: (() -> Void)?
    
    init(title: String, type: AlertPopupOptionType = .normal, action: (() -> Void)? = nil) {
        self.title = title
        self.type = type
        self.action = action
    }
    
}

// MARK: - Alert popup option view element
internal class AlertPopupOptionTableViewCell: UITableViewCell {
    
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    
    public func configure(_ option: AlertPopupOption) {
        switch option.type {
        case .normal:
            titleLabel.textColor = StyleHelper.colors.darkBlue
        case .cancel:
            titleLabel.textColor = StyleHelper.colors.darkBlueDisabled
        }
        
        titleLabel.text = option.title
    }
    
}
