//
//  AddLocationCardViewController.swift
//  Flo
//
//  Created by Nicolás Stefoni on 03/06/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class AddLocationCardViewController: CardViewController {
    
    @IBOutlet fileprivate weak var containerView: UIView!
    
    @IBAction fileprivate func addLocationAction() {
        let storyboard = UIStoryboard(name: "Locations", bundle: nil)
        if let controller = storyboard.instantiateViewController(
            withIdentifier: LocationTypeViewController.storyboardId) as? LocationTypeViewController {
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        containerView.backgroundColor = StyleHelper.colors.transparency
        containerView.clipsToBounds = true
        containerView.layer.cornerRadius = 10
        containerView.layer.addDashedBorder(withColor: StyleHelper.colors.darkBlueDisabled)
    }
    
}
