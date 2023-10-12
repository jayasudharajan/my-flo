//
//  EmailManager.swift
//  Flo
//
//  Created by Nicolás Stefoni on 17/05/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import MessageUI

internal enum MimeType: String {
    case textPlain = "text/plain"
}

internal enum FloEmails: String {
    case support = "support@flotechnologies.com"
    case contact = "contact@flotechnologies.com"
}

internal class EmailManager: NSObject, MFMailComposeViewControllerDelegate {
    
    public class var shared: EmailManager {
        struct Static {
            static let instance = EmailManager()
        }
        return Static.instance
    }
    
    fileprivate override init() {}
    
    public func sendEmail(to: String, subject: String, message: String, attachments: [Attachment] = []) {
        if MFMailComposeViewController.canSendMail() {
            let mailComposer = MFMailComposeViewController()
            mailComposer.setSubject(subject)
            mailComposer.setMessageBody(message, isHTML: false)
            mailComposer.setToRecipients([to])
            
            for attachment in attachments {
                mailComposer.addAttachmentData(
                    attachment.data, mimeType: attachment.mimeType.rawValue, fileName: attachment.name)
            }
            
            mailComposer.mailComposeDelegate = self
            UIApplication.shared.keyWindow?.rootViewController?.present(mailComposer, animated: true, completion: nil)
        } else {
            let alertController = UIAlertController(
                title: "Flo",
                message: "Sorry, but we didn't find an email account configured on your phone",
                preferredStyle: .alert
            )
            alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            
            UIApplication.shared.keyWindow?.rootViewController?.present(
                alertController,
                animated: true,
                completion: nil
            )
        }
    }
    
    public func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result: MFMailComposeResult,
        error: Error?
    ) {
        controller.dismiss(animated: true)
    }
    
}

internal class Attachment {
    
    public let name: String
    public let mimeType: MimeType
    public let data: Data
    
    public init(name: String, mimeType: MimeType, data: Data) {
        self.name = name
        self.mimeType = .textPlain
        self.data = data
    }
    
}
