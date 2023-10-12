//
//  FloGlobalWebRequest.swift
//  Flo
//
//  Created by Maurice Bachelor on 3/30/16.
//  Copyright © 2016 Flo Technologies. All rights reserved.
//

import Alamofire
import SwiftyJSON

internal final class FloWebRequest: FloRequest {
    
    fileprivate var baseURL = (PlistHelper.valueForKey("FloAPIUri") as? String ?? "")
    
    // MARK: FloApiRequestProtocol
    required init(
        method: RequestMethodType,
        url: String,
        queryString: [String: String]?,
        data: [String: AnyObject]?,
        requestHeaders: [String: String]?,
        usingBaseUrl: Bool = true,
        done: @escaping (_ error: FloRequestErrorModel?, _ data: AnyObject?) -> Void
    ) {
        let fullUrl = usingBaseUrl ? baseURL + url : url
        super.init(
            method: method,
            url: fullUrl,
            queryString: queryString,
            data: data,
            requestHeaders: requestHeaders,
            done: done
        )
    }
    
    // MARK: Public Interface
    
    public override func request() {
        if !FloGlobalServices.instance.isConnected() {
            LoggerHelper.log("No Internet Detected", level: .error)
            let error = FloRequestErrorModel(
                title: "error_popup_title".localized() + " 008",
                message: "no_internet_connection_detected".localized,
                status: nil)
            return requestClosure(error, nil)
        }
        
        switch requestMethod as RequestMethodType {
        case RequestMethodType.get:
            getRequest()
        case RequestMethodType.post:
            postRequest(requestData)
        case RequestMethodType.put:
            putRequest(requestData)
        case RequestMethodType.delete:
            deleteRequest()
        }
    }
    
    // MARK: Private methods
    
    fileprivate func getRequest() {
        let url = URLRequest(url: URL(string: finalUrl)!).url?.absoluteString
        FloApiManager.shared.manager.request(
            url!,
            method: .get,
            parameters: nil,
            encoding: JSONEncoding.default,
            headers: requestHeaders
        ).responseJSON(completionHandler: { (response) in
            self.handleResponse(response: response)
        })
    }
    
    fileprivate func postRequest(_ data: [String: AnyObject]?) {
        let url = URLRequest(url: URL(string: finalUrl)!).url?.absoluteString
        FloApiManager.shared.manager.request(
            url!,
            method: .post,
            parameters: data,
            encoding: JSONEncoding.default,
            headers: requestHeaders
        ).responseJSON(completionHandler: { (response) in
            self.handleResponse(response: response)
        })
    }
    
    fileprivate func putRequest(_ data: [String: AnyObject]?) {
        let url = URLRequest(url: URL(string: finalUrl)!).url?.absoluteString
        FloApiManager.shared.manager.request(
            url!,
            method: .put,
            parameters: data,
            encoding: JSONEncoding.default,
            headers: requestHeaders
        ).responseJSON(completionHandler: { (response) in
            self.handleResponse(response: response)
        })
    }
    
    fileprivate func deleteRequest() {
        let url = URLRequest(url: URL(string: finalUrl)!).url?.absoluteString
        FloApiManager.shared.manager.request(
            url!,
            method: .delete,
            parameters: nil,
            encoding: JSONEncoding.default,
            headers: requestHeaders
        ).responseJSON(completionHandler: { (response) in
            self.handleResponse(response: response)
        })
    }
    
    fileprivate func handleResponse(response: DataResponse<Any>) {
        if let r = response.response {
            if r.statusCode >= 200 && r.statusCode < 400 {
                if let value = response.result.value {
                    let body = JSON(value).rawString() ?? ""
                    LoggerHelper.log("API_CALL:\(finalUrl)\nSTATUS:\(r.statusCode)\nBODY:\(body)", level: .verbose)
                    self.requestClosure(nil, value as AnyObject)
                } else {
                    LoggerHelper.log("API_CALL:\(finalUrl)\nSTATUS:\(r.statusCode)", level: .verbose)
                    self.requestClosure(nil, true as AnyObject)
                }
            } else {
                handleErrorResponse(r.statusCode, response: response)
            }
        } else {
            let error = FloRequestErrorModel(title: "error_popup_title".localized() + " 009",
                                             message: "cannot_communicate_with_flo_servers".localized,
                                             status: nil)
            self.requestClosure(error, nil)
        }
    }
    
    fileprivate func handleErrorResponse(_ status: Int, response: DataResponse<Any>) {
        var serverMessage: String?
        var errorMessage = "Unknown"
        if response.result.error != nil && status != 401 {
            LoggerHelper.log("API_CALL:\(finalUrl)\nSTATUS:\(status)\nMESSAGE:\(response.result.error!.localizedDescription)", level: .error)
            errorMessage = response.result.error!.localizedDescription
        } else {
            if let value = response.result.value as? [String: AnyObject] {
                if let apiMessage = value["message"] as? String {
                    LoggerHelper.log("API_CALL:\(finalUrl)\nSTATUS:\(status))\nMESSAGE:\(apiMessage)", level: .error)
                    serverMessage = apiMessage
                    errorMessage = apiMessage
                } else {
                    LoggerHelper.log("API_CALL:\(finalUrl)\nSTATUS:\(status)\nUNKNOWN ERROR", level: .error)
                }
            } else {
                LoggerHelper.log("API_CALL:\(finalUrl)\nSTATUS:\(status)\nUNKNOWN ERROR", level: .error)
            }
        }
        
        let error = FloRequestErrorModel(title: "error_popup_title".localized() + " 009",
                                         message: getGeneralErrorMessage(status),
                                         status: status,
                                         serverMessage: serverMessage ?? errorMessage)
        return self.requestClosure(error, nil)
    }
}
