//
//  InAppMessageManager.swift
//  Flo
//
//  Created by Nicolás Stefoni on 25/04/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import FirebaseInAppMessaging

class InAppMessageManager: NSObject, InAppMessagingDisplayDelegate {
    
    static let instance = InAppMessageManager()
    
    func showMessage(_ data: NSDictionary) {
        if let imageUrlString = data["bigPicture"] as? String, let imageUrl = URL(string: imageUrlString) {
            loadImage(from: imageUrl, andShow: data)
        } else {
            show(data)
        }
    }
    
    // MARK: - Private methods
    func loadImage(from url: URL, andShow messageData: NSDictionary) {
        URLSession.shared.dataTask(with: url) { (data, _, error) in
            if var imageData = data, error == nil {
                imageData = UIImage(data: imageData)?.pngData() ?? Data()
                self.show(messageData, with: InAppMessagingImageData(imageURL: url.absoluteString, imageData: imageData))
            } else {
                self.show(messageData)
            }
        }.resume()
    }
    
    func show(_ data: NSDictionary, with imageData: InAppMessagingImageData? = nil) {
        let actionUrl = URL(string: data["action"] as? String ?? "")
        let backgroundColor = UIColor(hex: data["backgroundColor"] as? String ?? "#FFFFFF")
        
        guard
            let titleData = data["title"] as? NSDictionary,
            let titleText = titleData["text"] as? String,
            let titleHexaCode = titleData["textColor"] as? String,
            let bodyData = data["body"] as? NSDictionary,
            let bodyText = bodyData["text"] as? String
        else {
            if let imageDataUW = imageData {
                let imageOnlyDisplay = InAppMessagingImageOnlyDisplay(messageID: "", campaignName: "", renderAsTestMessage: true, triggerType: .onAppForeground, imageData: imageDataUW, actionURL: actionUrl)
                InAppMessaging.inAppMessaging().messageDisplayComponent.displayMessage(imageOnlyDisplay, displayDelegate: self)
            }
            return
        }
        
        guard
            let buttonData = data["button"] as? NSDictionary,
            let buttonText = buttonData["text"] as? String,
            let textHexaCode = buttonData["textColor"] as? String,
            let bkgHexaColor = buttonData["backgroundColor"] as? String
        else {
            let bannerDisplay = InAppMessagingBannerDisplay(messageID: "", campaignName: "", renderAsTestMessage: true, triggerType: .onAppForeground, titleText: titleText, bodyText: bodyText, textColor: UIColor(hex: titleHexaCode), backgroundColor: backgroundColor, imageData: imageData, actionURL: actionUrl)
            InAppMessaging.inAppMessaging().messageDisplayComponent.displayMessage(bannerDisplay, displayDelegate: self)
            return
        }
        
        let actionButton = InAppMessagingActionButton(buttonText: buttonText, buttonTextColor: UIColor(hex: textHexaCode), backgroundColor: UIColor(hex: bkgHexaColor))
        let modalDisplay = InAppMessagingModalDisplay(messageID: "", campaignName: "", renderAsTestMessage: true, triggerType: .onAppForeground, titleText: titleText, bodyText: bodyText, textColor: UIColor(hex: titleHexaCode), backgroundColor: backgroundColor, imageData: imageData, actionButton: actionButton, actionURL: actionUrl)
        InAppMessaging.inAppMessaging().messageDisplayComponent.displayMessage(modalDisplay, displayDelegate: self)
    }
    
    // MARK: - InAppMessagingDisplayDelegate protocol methods
    func messageDismissed(_ inAppMessage: InAppMessagingDisplayMessage, dismissType: FIRInAppMessagingDismissType) {
        
    }
    
    func messageClicked(_ inAppMessage: InAppMessagingDisplayMessage) {
        if let message = inAppMessage as? InAppMessagingModalDisplay, let actionURL = message.actionURL {
            if UIApplication.shared.canOpenURL(actionURL) {
                UIApplication.shared.openURL(actionURL)
            }
        } else if let message = inAppMessage as? InAppMessagingBannerDisplay, let actionURL = message.actionURL {
            if UIApplication.shared.canOpenURL(actionURL) {
                UIApplication.shared.openURL(actionURL)
            }
        }
    }
    
    func impressionDetected(for inAppMessage: InAppMessagingDisplayMessage) {
        
    }
    
    func displayError(for inAppMessage: InAppMessagingDisplayMessage, error: Error) {
        
    }
    
}
