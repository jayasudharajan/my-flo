//
//  ChatManager.swift
//  Flo
//
//  Created by Nicolás Stefoni on 6/4/18.
//  Copyright © 2018 Flo Technologies. All rights reserved.
//

import ZDCChat
import IQKeyboardManager

// DON'T ERASE THIS
// Set this text for "No agents message" key on ZDCChat localization files whenever you do a pod update:
// Sorry, there are no agents available to chat. Please try again later or leave us a message.                                                                                Flo Support agents are available                                                                                Mon-Fri: 8am-6pm pt

internal class ChatHelper {
    
    public class func initialize() {
        ZDCChat.setupUI()
        ZDCChat.initialize(withAccountKey: "49xQ8TjmnmOyykHkx9Zs4iotnT8kyBXW")
    }
    
    public class func setupAndStart(in navigationController: UINavigationController?, status: String) {
        if let session = UserSessionManager.shared.user {
            ZDCChat.updateVisitor { user in
                user?.name = session.firstName
                user?.email = session.email
            }
        }
            
        ZDCChat.start(in: navigationController, withConfig: { config in
            config?.tags = [status]
            config?.preChatDataRequirements.email = .required
            config?.uploadAttachmentsEnabled = true
        })
            
        if let chatViewCtrl = ZDCChat.instance().chatViewController, let chatNavCtrl = chatViewCtrl.navigationController {
            let view = UIView(frame: CGRect(x: 0, y: 0, width: chatViewCtrl.view.frame.width, height: chatNavCtrl.navigationBar.frame.origin.y + chatNavCtrl.navigationBar.frame.height))
            view.backgroundColor = StyleHelper.colors.blue
            chatViewCtrl.view.addSubview(view)
            
            chatNavCtrl.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: StyleHelper.font(sized: .large)]
            chatNavCtrl.navigationBar.tintColor = .white
            
            IQKeyboardManager.shared().isEnabled = false
            IQKeyboardManager.shared().isEnableAutoToolbar = false
            IQKeyboardManager.shared().shouldResignOnTouchOutside = false
        }
    }
    
}
