//
//  FloGlobalWebRequest.swift
//  Flo
//
//  Created by Maurice Bachelor on 3/30/16.
//  Copyright © 2016 Flo Technologies. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

open class FloGlobalWebRequest {
    
    var url: String?
    var finalUrl: String
    var requestMethod: RequestMethodType
    var requestData: [String: AnyObject]?
    var requestClosure: (AnyObject) -> Void
    var requestHeaders: [String: String]?
    
    init(method: RequestMethodType, url: String, queryString: [String: String]?, data: [String: AnyObject]?, requestHeaders: [String: String]?, done: @escaping (AnyObject) -> Void) {
        requestMethod = method
        finalUrl = url
        requestData = data
        requestClosure = done
        self.requestHeaders = requestHeaders
        if let qs = queryString {
            addQueryString(qs)
        }
    }
    
    open func request() {
        switch requestMethod as RequestMethodType {
        case RequestMethodType.get:
            getRequest(requestClosure)
        case RequestMethodType.post:
            postRequest(requestData, done: requestClosure)
        case RequestMethodType.put:
            putRequest(data: requestData, done: requestClosure)
        default:
            break
        }
    }
    
    fileprivate func getRequest(_ done: @escaping (AnyObject) -> Void) {
        if FloGlobalServices.instance.isConnected {
            let url = URLRequest(url: URL(string: finalUrl)!).url?.absoluteString
            FloApiManager.sharedInstance.manager.request(url!, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: requestHeaders).responseJSON(completionHandler: { (response) in
                self.handleResponse(response: response, done: done)
            })
        } else {
            done(FloRequestErrorModel(message: "No Internet Detected. Please try again later.", status: nil))
        }
    }
    
    fileprivate func postRequest(_ data: [String: AnyObject]?, done: @escaping (AnyObject) -> Void) {
        if FloGlobalServices.instance.isConnected {
            let url = URLRequest(url: URL(string: finalUrl)!).url?.absoluteString
            FloApiManager.sharedInstance.manager.request(url!, method: .post, parameters: data, encoding: JSONEncoding.default, headers: requestHeaders).responseJSON(completionHandler: { (response) in
                self.handleResponse(response: response, done: done)
            })
        } else {
            done(FloRequestErrorModel(message: "No Internet Detected. Please try again later.", status: nil))
        }
    }
    
    fileprivate func putRequest(data: [String: AnyObject]?, done: @escaping (AnyObject) -> Void) {
        if FloGlobalServices.instance.isConnected {
            let url = URLRequest(url: URL(string: finalUrl)!).url?.absoluteString
            FloApiManager.sharedInstance.manager.request(url!, method: .put, parameters: data, encoding: JSONEncoding.default, headers: requestHeaders).responseJSON(completionHandler: { (response) in
                self.handleResponse(response: response, done: done)
            })
        } else {
            done(FloRequestErrorModel(message: "No Internet Detected. Please try again later.", status: nil))
        }
    }
    
    fileprivate func handleResponse(response: DataResponse<Any>, done: @escaping (AnyObject) -> Void) {
        if let r = response.response {
            if r.statusCode == 200 {
                if let JSON = response.result.value {
                    done(JSON as AnyObject)
                } else {
                    done(true as AnyObject)
                }
            } else {
                handleErrorResponse(r.statusCode, response: response, done: done)
            }
        } else {
            done(FloRequestErrorModel(message: "Please check your internet connection", status: nil))
        }
    }
    
    func handleErrorResponse(_ status: Int, response: DataResponse<Any>, done: @escaping (AnyObject) -> Void) {
        if response.result.error != nil && status != 401 {
            done(FloRequestErrorModel(message: response.result.error!.localizedDescription, status: status))
        } else {
            if let value = response.result.value as? [String: AnyObject] {
                if let apiMessage = value["message"] as? String {
                    done(FloRequestErrorModel(message: (status != 401 ? apiMessage : getGeneralErrorMessage(status)), status: status))
                } else {
                    done(FloRequestErrorModel(message: getGeneralErrorMessage(status), status: status))
                }
            } else {
                done(FloRequestErrorModel(message: getGeneralErrorMessage(status), status: status))
            }
        }
    }
    
    fileprivate func getGeneralErrorMessage(_ status: Int, message: String? = nil) -> String {
        switch status {
        case 400:
            return "Bad Request"
        case 401:
            tokenLogout(message: message)
            return message != nil ? message! : "Your session has expired. Please log in again."
        case 404:
            return "Request Not Found"
        case 409:
            return "This ICD has already been paired"
        case 500:
            return "A Server Error Has Occured. Please Try Again"
        default:
            return "An Error Has Occurend"
        }
    }
    
    func addQueryString(_ qString: [String: String]) {
        if qString.count > 0 {
            for qs in qString {
                finalUrl += "\(qs.0)="
                finalUrl += "\(qs.1)&"
            }
        }
    }
    
    fileprivate func tokenLogout(message: String?) {
        TrackingManager.shared.track("deleted_user_case_A")
        if var topController = UIApplication.shared.keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            if topController is LoginViewController || topController is SignupViewController {
                LoggerHelper.log("TOKEN LOGOUT", level: .warning)
            } else if let navController = topController as? UINavigationController, (navController.topViewController is LoginViewController || navController.topViewController is SignupViewController) {
                LoggerHelper.log("TOKEN LOGOUT", level: .warning)
            } else {
                _ = SwiftSpinner.show("Please wait")
                
                let logoutUser = [
                    "mobile_device_id": (UIDevice.current.identifierForVendor?.uuidString as AnyObject),
                    "aws_endpoint_id": (AWSPinpointManager.shared.getCurrentEndpointId() as AnyObject)
                ]
                
                FloApiRequest(controller: "logout", method: .post, queryString: nil, data: logoutUser, done: { _ in
                    SwiftSpinner.hide()
                    FloGlobalUser.sharedInstance.deleteUser()
                    
                    let storyboard = UIStoryboard(name: "Login", bundle: nil)
                    if let login = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController {
                        login.authErrorMesssage = message
                        
                        UIApplication.shared.keyWindow?.rootViewController = UINavigationController(rootViewController: login)
                        UIApplication.shared.keyWindow?.makeKeyAndVisible()
                    }
                }).floRequest()
            }
        }
    }
}
