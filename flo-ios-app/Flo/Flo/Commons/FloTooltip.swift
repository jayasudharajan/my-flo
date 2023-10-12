//
//  FloTooltip.swift
//  Flo
//
//  Created by Nicolás Stefoni on 24/05/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import EasyTipView

internal enum TooltipType {
    case error, info, data
}

internal class FloTooltip {
    
    fileprivate static let currentTooltipsSemaphore = DispatchSemaphore(value: 1)
    fileprivate static var currentTooltips: [EasyTipView] = []
    
    fileprivate static var initialized = false
    fileprivate var tooltip: EasyTipView!
    
    init(create type: TooltipType, pointing arrowPosition: EasyTipView.ArrowPosition = .any, saying text: String, delegate: EasyTipViewDelegate? = nil) {
        if !FloTooltip.initialized {
            initialize()
        }
        
        var backgroundColor = UIColor.white
        var foregroundColor = UIColor.black
        
        switch type {
        case .error:
            backgroundColor = StyleHelper.colors.red
            foregroundColor = .white
        case .info:
            backgroundColor = StyleHelper.colors.blue
            foregroundColor = .white
        case .data:
            backgroundColor = StyleHelper.colors.lightGray
            foregroundColor = .black
        }
        
        var preferences = EasyTipView.globalPreferences
        preferences.drawing.backgroundColor = backgroundColor
        preferences.drawing.foregroundColor = foregroundColor
        preferences.drawing.arrowPosition = arrowPosition
        
        tooltip = EasyTipView(text: text, preferences: preferences, delegate: delegate)
        
        FloTooltip.currentTooltipsSemaphore.wait()
        //Add tooltip to global array in order to be able to delete all of them withouth searching the views tree
        FloTooltip.currentTooltips.append(tooltip)
        FloTooltip.currentTooltipsSemaphore.signal()
    }
    
    fileprivate func initialize() {
        FloTooltip.initialized = true
        
        var preferences = EasyTipView.Preferences()
        preferences.drawing.font = StyleHelper.font(sized: FontSize.tiny)
        preferences.drawing.foregroundColor = .white
        preferences.drawing.arrowPosition = .bottom
        preferences.drawing.cornerRadius = 10
        EasyTipView.globalPreferences = preferences
    }
    
    public func show(over target: UIView) {
        if target.tag == 0 {
            target.tag = Int.random(in: 1 ... 666)
        }
        
        tooltip.tag = target.tag
        tooltip.show(forView: target, withinSuperview: target.superview)
    }
    
    public func dismiss() {
        tooltip.dismiss()
    }
    
    public class func remove(from view: UIView, cleaningAllOtherBubbles: Bool = true) {
        
        FloTooltip.currentTooltipsSemaphore.wait()
        
        if cleaningAllOtherBubbles {
            for tooltip in FloTooltip.currentTooltips {
                tooltip.dismiss()
            }
            FloTooltip.currentTooltips = []
        } else {
            for (index, tooltip) in FloTooltip.currentTooltips.enumerated() where tooltip.tag == view.tag {
                tooltip.dismiss()
                FloTooltip.currentTooltips.remove(at: index)
                break
            }
        }
        
        FloTooltip.currentTooltipsSemaphore.signal()
    }
    
}
