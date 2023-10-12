//
//  FloImageOptionButton.swift
//  Flo
//
//  Created by Matias Paillet on 6/19/19.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

@IBDesignable
internal class FloImageOptionButton: FloOptionButton {
    
    fileprivate var background: FloImageOptionButtonBackground?
    
    @IBInspectable var centerImage: String?
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.background = FloImageOptionButtonBackground.instanceFromNib()
        self.background?.frame = CGRect(origin: CGPoint(x: 0, y: 0 ), size: self.frame.size)
        self.background?.configure(self.title(for: .normal) ?? "", centerImage: centerImage)
        self.addSubview(self.background!)
        
        self.setTitle("", for: .normal)
        
        //Create a button to cover everything and redirect to the real target
        let button = UIButton(frame: CGRect(origin: CGPoint(x: 0, y: 0 ), size: self.frame.size))
        button.backgroundColor = UIColor.clear
        button.addTarget(self, action: #selector(forwardTouchUpInside), for: .touchUpInside)
        self.addSubview(button)
    }
    
    override public func configureForSelected() {
        super.configureForSelected()
        self.background?.setSelected(true)
    }
    
    override public func configureForUnselected() {
        super.configureForUnselected()
        self.background?.setSelected(false)
    }
    
    @objc func forwardTouchUpInside() {
        self.sendActions(for: .touchUpInside)
    }
}
