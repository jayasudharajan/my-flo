//
// Copyright (c) 2015-2016 Marin Todorov, Underplot ltd.
// This code is distributed under the terms and conditions of the MIT license.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import UIKit

open class SwiftSpinner: UIView {
    
    // MARK: - Singleton
    
    //
    // Access the singleton instance
    //
    open class var sharedInstance: SwiftSpinner {
        struct Singleton {
            static let instance = SwiftSpinner(frame: CGRect(x: 0,
                                                             y: 0,
                                                             width: UIScreen.main.bounds.width,
                                                             height: UIScreen.main.bounds.height))
        }
        return Singleton.instance
    }
    
    // MARK: - Private properties
    
    //
    // layout elements
    //
    
    fileprivate var activityIndicator: UIActivityIndicatorView?
    
    // MARK: - Init
    
    //
    // Custom init to build the spinner UI
    //
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
        activityIndicator?.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        self.addSubview(activityIndicator!)

        isUserInteractionEnabled = false
    }
    
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return self
    }
    
    // MARK: - Public interface
    //
    // Custom superview for the spinner
    //
    fileprivate static weak var customSuperview: UIView?
    fileprivate static func containerView() -> UIView? {
        return customSuperview ?? UIApplication.shared.keyWindow
    }
    open class func useContainerView(_ sv: UIView?) {
        customSuperview = sv
    }
    
    //
    // Show the spinner activity on screen, if visible only update the title
    //
    open class func show(_ title: String? = "", animated: Bool = true) -> SwiftSpinner {
        
        let spinner = SwiftSpinner.sharedInstance
        
        spinner.updateFrame()
        
        if spinner.superview == nil {
            //show the spinner
            spinner.alpha = 0.0
            spinner.activityIndicator?.startAnimating()
            
            guard let containerView = containerView() else {
                fatalError("\n`UIApplication.keyWindow` is `nil`. If you're trying to show a spinner from your view controller's `viewDidLoad` method, do that from `viewWillAppear` instead. Alternatively use `useContainerView` to set a view where the spinner should show")
            }
            
            containerView.addSubview(spinner)

            UIView.animate(withDuration: 0.33, delay: 0.0, options: .curveEaseOut, animations: {
                spinner.alpha = 1.0
                }, completion: { _ in
                    UIView.animate(withDuration: 0.33, animations: {}, completion: nil)
            })
            
            #if os(iOS)
            // Orientation change observer
            NotificationCenter.default.addObserver(
                spinner,
                selector: #selector(SwiftSpinner.updateFrame),
                name: UIApplication.didChangeStatusBarOrientationNotification,
                object: nil)
            #endif
        }
        
        return spinner
    }
    
    //
    // Show the spinner activity on screen with duration, if visible only update the title
    //
    open class func showWithDuration(_ duration: Double, title: String, animated: Bool = true) -> SwiftSpinner {
        let spinner = SwiftSpinner.show(title, animated: animated)
        spinner.delay(seconds: duration) {
            SwiftSpinner.hide()
        }
        return spinner
    }
    
    fileprivate static var delayedTokens = [String]()
    //
    // Show the spinner activity on screen, after delay. If new call to show,
    // showWithDelay or hide is maked before execution this call is discarded
    //
    open class func showWithDelay(_ delay: Double, title: String, animated: Bool = true) {
        let token = UUID().uuidString
        delayedTokens.append(token)
        SwiftSpinner.sharedInstance.delay(seconds: delay, completion: {
            if let index = delayedTokens.firstIndex(of: token) {
                delayedTokens.remove(at: index)
                _ = SwiftSpinner.show(title, animated: animated)
            }
        })
    }
    
    //
    // Hide the spinner
    //
    public static var hideCancelsScheduledSpinners = true
    open class func hide(_ completion: (() -> Void)? = nil) {
        
        let spinner = SwiftSpinner.sharedInstance
        
        NotificationCenter.default.removeObserver(spinner)
        if hideCancelsScheduledSpinners {
            delayedTokens.removeAll()
        }
        
        DispatchQueue.main.async(execute: {
            
            if spinner.superview == nil {
                return
            }
            UIView.animate(withDuration: 0.33, animations: {}, completion: { _ in
                    UIView.animate(withDuration: 0.33, delay: 0.0, options: .curveEaseOut, animations: {
                        spinner.alpha = 0.0
                        }, completion: {_ in
                            spinner.alpha = 1.0
                            spinner.activityIndicator?.stopAnimating()
                            spinner.removeFromSuperview()
                            completion?()
                    })
            })
        })
    }
    
    //
    // observe the view frame and update the subviews layout
    //
    open override var frame: CGRect {
        didSet {
            if frame == CGRect.zero {
                return
            }
            
            if activityIndicator != nil {
                activityIndicator?.center = CGPoint(x: self.frame.midX, y: self.frame.midY)
            }
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("Not coder compliant")
    }
    
    @objc open func updateFrame() {
        if let containerView = SwiftSpinner.containerView() {
            SwiftSpinner.sharedInstance.frame = containerView.bounds
        }
    }
    
    // MARK: - Util methods
    
    func delay(seconds: Double, completion: @escaping () -> Void) {
        let popTime = DispatchTime.now() + Double(Int64( Double(NSEC_PER_SEC) * seconds )) / Double(NSEC_PER_SEC)
        
        DispatchQueue.main.asyncAfter(deadline: popTime) {
            completion()
        }
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        updateFrame()
    }
}
