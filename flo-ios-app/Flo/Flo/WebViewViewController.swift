//
//  WebViewViewController.swift
//  Flo
//
//  Created by Josefina Perez on 29/07/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit
import WebKit

internal class WebViewViewController: FloBaseViewController {
    
    @IBOutlet fileprivate weak var webView: UIWebView!
    
    var headerTitle: String?
    var urlString: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.layer.addGradient(from: StyleHelper.colors.darkBlue, to: StyleHelper.colors.gradient1Secondary, angle: 90)
        
        setupNavBarWithBack(andTitle: headerTitle ?? "", tint: StyleHelper.colors.white, titleColor: StyleHelper.colors.white)
        
        guard let url = URL(string: urlString ?? "") else {
            return
        }
        
        let requestObj = URLRequest(url: url)
        webView.loadRequest(requestObj)
    }
    
    // MARK: - Overrides
    override func shouldHideNavBar() -> Bool {
        return false
    }
}
