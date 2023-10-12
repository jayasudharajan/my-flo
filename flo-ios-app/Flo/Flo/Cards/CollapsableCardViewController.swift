//
//  CollapsableCardViewController.swift
//  Flo
//
//  Created by Nicolás Stefoni on 30/07/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal protocol CollapsableCardDelegate: class {
    func cardHasResized(_ cardViewController: CardViewController)
}

internal class CollapsableCardViewController: CardViewController {
    
    public let kCollapsedHeight: CGFloat = 74
    fileprivate(set) var isCollapsed = false
    fileprivate(set) weak var delegate: CollapsableCardDelegate?
    
    @IBOutlet public weak var containerView: UIView!
    @IBOutlet public weak var titleLabel: UILabel!
    
    @IBAction public func resizeAction(_ sender: UIButton) {
        isCollapsed = !isCollapsed
        sender.setTitle(isCollapsed ? "+" : "-", for: .normal)
        delegate?.cardHasResized(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        containerView.layer.cornerRadius = 10
    }
    
    public func setDelegate(_ delegate: CollapsableCardDelegate) {
        self.delegate = delegate
    }

}
