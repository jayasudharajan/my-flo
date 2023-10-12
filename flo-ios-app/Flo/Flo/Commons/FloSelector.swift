//
//  FloSelector.swift
//  Flo
//
//  Created by Nicolás Stefoni on 30/05/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal protocol FloSelectorProtocol: class {
    func valueDidChange(selectedIndex: Int)
}

internal enum FloSelectorStyle: Int {
    case primary = 0, secondary
}

internal class FloSelector: UIView {
    
    public weak var delegate: FloSelectorProtocol?
    
    fileprivate(set) var selectedIndex = 0
    fileprivate var lastIndex = 0
    fileprivate let selectorView = UIView()
    fileprivate var rawOptions: [String] = []
    fileprivate var optionViews: [UILabel] = []
    fileprivate var optionViewWidth: CGFloat = 0
    fileprivate var positions: [CGPoint] = []
    
    // Styling
    fileprivate var style = FloSelectorStyle.primary
    fileprivate let selectorColors = [StyleHelper.colors.white, StyleHelper.colors.white]
    fileprivate let backgroundColors = [StyleHelper.colors.transparencyHighlight, StyleHelper.colors.gray]
    fileprivate let selectorLabelColors = [StyleHelper.colors.black, StyleHelper.colors.black]
    fileprivate let optionColors = [StyleHelper.colors.blue, StyleHelper.colors.darkGray]
    
    public var isEnabled: Bool {
        get {
            return isUserInteractionEnabled
        }
        set {
            selectorView.isHidden = !newValue
            isUserInteractionEnabled = newValue
        }
    }
    
    public func setStyle(_ style: FloSelectorStyle) {
        self.style = style
        refreshUI()
    }
    
    public func setOptions(_ options: [String]) {
        rawOptions = options.isEmpty ? ["Empty"] : options
        selectedIndex = options.count - 1
        lastIndex = selectedIndex
        
        refreshUI()
    }
    
    public func selectOptionWithoutTriggers(_ index: Int) {
        if index < rawOptions.count {
            selectedIndex = index
            lastIndex = index
            
            for option in optionViews {
                option.textColor = optionColors[style.rawValue]
            }
            selectorView.layer.removeAllAnimations()
            UIView.animate(withDuration: 0.1) {
                self.selectorView.frame.origin = self.positions[index]
            }
        }
    }
    
    public func refreshUI() {
        calculateMeasures()
        redraw()
    }
    
    fileprivate func calculateMeasures() {
        optionViewWidth = 0
        positions = []
        
        optionViewWidth = frame.width / CGFloat(rawOptions.count)
        for i in 0 ..< rawOptions.count {
            positions.append(CGPoint(x: (CGFloat(i) * optionViewWidth), y: 0))
        }
        
        if !positions.isEmpty {
            selectorView.frame = CGRect(origin: positions[selectedIndex], size: CGSize(width: optionViewWidth, height: frame.height))
        }
    }
    
    fileprivate func redraw() {
        // Styling
        layer.cornerRadius = frame.height / 2
        backgroundColor = backgroundColors[style.rawValue]
        
        selectorView.layer.cornerRadius = frame.height / 2
        selectorView.layer.shadowColor = StyleHelper.colors.black.cgColor
        selectorView.layer.shadowRadius = 4
        selectorView.layer.shadowOpacity = 0.2
        selectorView.layer.shadowOffset = CGSize(width: 0, height: 4)
        selectorView.backgroundColor = selectorColors[style.rawValue]
        
        // Remove replace components
        for view in subviews {
            view.removeFromSuperview()
        }
        addSubview(selectorView)
        for (i, rawOption) in rawOptions.enumerated() {
            let option = instanceOption(rawOption, at: i)
            optionViews.append(option)
            addSubview(option)
        }
    }
    
    fileprivate func instanceOption(_ title: String, at: Int) -> UILabel {
        let label = UILabel(frame: CGRect(
            x: positions[at].x + 8,
            y: positions[at].y,
            width: optionViewWidth - 16,
            height: frame.height
        ))
        label.text = title
        label.textAlignment = .center
        label.font = StyleHelper.font(sized: .small)
        label.textColor = at == selectedIndex ? selectorLabelColors[style.rawValue] : optionColors[style.rawValue]
        label.adjustsFontSizeToFitWidth = true
        label.numberOfLines = 2
        label.tag = at
        label.isUserInteractionEnabled = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapOption(_:)))
        label.addGestureRecognizer(tapGesture)
        
        return label
    }
    
    // MARK: - Tap option gesture callback
    @objc public func tapOption(_ sender: Any) {
        for option in optionViews {
            option.textColor = optionColors[style.rawValue]
        }
        
        if let gestureRecognizer = sender as? UITapGestureRecognizer, let label = gestureRecognizer.view as? UILabel {
            label.layer.removeAllAnimations()
            selectorView.layer.removeAllAnimations()
            
            UIView.animate(withDuration: 0.1) {
                label.textColor = self.selectorLabelColors[self.style.rawValue]
                self.selectorView.frame.origin = self.positions[label.tag]
            }
            
            if label.tag != selectedIndex {
                lastIndex = selectedIndex
                selectedIndex = label.tag
                delegate?.valueDidChange(selectedIndex: selectedIndex)
            }
        }
    }
    
    public func cancelLastTap() {
        for option in optionViews {
            option.textColor = optionColors[style.rawValue]
        }
        
        selectorView.layer.removeAllAnimations()
        UIView.animate(withDuration: 0.1) {
            self.selectorView.frame.origin = self.positions[self.lastIndex]
        }
        
        selectedIndex = lastIndex
    }
    
    // MARK: - Refreshing UI each time it's necessary
    override func layoutSubviews() {
        super.layoutSubviews()
        
        refreshUI()
    }
    
}
