//
//  FloMockedRequest.swift
//  Flo
//
//  Created by Matias Paillet on 5/17/19.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import SwiftyJSON

internal final class FloMockedRequest: FloRequest {
    
    fileprivate static let k200OKMessage = "200ok"
    fileprivate static let kMockedUserId = "ffbddca2-0a18-4adb-899c-d2cfc3bf44fc"
    
    override public func request() {
        let fileName = self.getFileName()
        guard let path = Bundle.main.path(forResource: fileName, ofType: "json") else {
            //If file not found, simulate a 404 error
            LoggerHelper.log("API_CALL:\(fileName)\nMESSAGE: File not Found", level: .warning)
            return DispatchQueue.main.async {
                let error = FloRequestErrorModel(title: "error_popup_title".localized() + " 009",
                                                 message: self.getGeneralErrorMessage(404),
                                                 status: 404)
                self.requestClosure(error, nil)
            }
        }
        
        do {
            let fileContent = try String(contentsOfFile: path, encoding: .utf8).replacingOccurrences(of: "\n", with: "")
            if fileContent == FloMockedRequest.k200OKMessage {
                //If file exists but has 200ok in it, just return true as base service does.
                return DispatchQueue.main.async {
                    self.requestClosure(nil, true as AnyObject)
                }
            } else {
                let content = JSON(parseJSON: fileContent)
                return DispatchQueue.main.async {
                    self.requestClosure(nil, content.dictionaryObject as AnyObject)
                }
            }
        } catch {}
        return
    }
    
    fileprivate func getFileName() -> String {
        var string = "\(requestMethod.toString().lowercased())_\(finalUrlNoParams.lowercased())"
            .replacingOccurrences(of: "/", with: "_")
        
        if let userId = UserSessionManager.shared.authorization?.userId {
            string = string.replacingOccurrences(of: userId, with: FloMockedRequest.kMockedUserId)
        }
        
        return string
    }
}
