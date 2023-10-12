//
//  FloRequest.swift
//  Flo
//
//  Created by Matias Paillet on 5/17/19.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

internal protocol FloApiRequestProtocol {
    init(
        method: RequestMethodType,
        url: String,
        queryString: [String: String]?,
        data: [String: AnyObject]?,
        requestHeaders: [String: String]?,
        usingBaseUrl: Bool,
        done: @escaping (_ error: FloRequestErrorModel?, _ data: AnyObject?) -> Void
    )
    func updateHeader(key: String, value: String)
    func request()
}

internal class FloRequest: FloApiRequestProtocol {
    public var finalUrl: String
    public var finalUrlNoParams: String
    public var requestMethod: RequestMethodType
    public var requestData: [String: AnyObject]?
    public var requestClosure: (_ error: FloRequestErrorModel?, _ data: AnyObject?) -> Void
    public var requestHeaders: [String: String]?
    
    fileprivate static var percentageEscapedCharacterSet = CharacterSet(charactersIn: "#%/<>?@\\^`{|}+").inverted
    
    // MARK: - FloApiRequestProtocol
    required init(
        method: RequestMethodType,
        url: String,
        queryString: [String: String]?,
        data: [String: AnyObject]?,
        requestHeaders: [String: String]?,
        usingBaseUrl: Bool = true,
        done: @escaping (_ error: FloRequestErrorModel?, _ data: AnyObject?) -> Void
    ) {
        requestMethod = method
        finalUrl = url
        finalUrlNoParams = url
        requestData = data
        requestClosure = done
        self.requestHeaders = requestHeaders
        if let qs = queryString {
            addParamsToQueryString(qs)
        }
    }
    
    public func request() {
        //EACH SUBCLASS NEEDS TO IMPLEMENT THIS METHOD
    }
    
    //Used for updating / adding headers dynamically.
    public func updateHeader(key: String, value: String) {
        requestHeaders?.updateValue(value, forKey: key)
    }
    
    public func getGeneralErrorMessage(_ status: Int, message: String? = nil) -> String {
        switch status {
        case 401:
            tokenLogout(message: message)
            return message != nil ? message! : "session_expired".localized
        default:
            return "cannot_communicate_with_flo_servers".localized
        }
    }
    
    // MARK: - Helper methods
    fileprivate func addParamsToQueryString(_ qString: [String: String]) {
        if qString.count > 0 {
            finalUrl += "?"
            for qs in qString {
                finalUrl += "\(qs.0)=".addingPercentEncoding(withAllowedCharacters: FloRequest.percentageEscapedCharacterSet)!
                finalUrl += "\(qs.1)&".addingPercentEncoding(withAllowedCharacters: FloRequest.percentageEscapedCharacterSet)!
            }
        }
        
        finalUrl = finalUrl.trimmingCharacters(in: CharacterSet(charactersIn: "&"))
    }
    
    fileprivate func tokenLogout(message: String?) {
        TrackingManager.shared.track("deleted_user_case_A")
        
        if let topController = UIApplication.topViewController() {
            if topController is LoginViewController || topController is SignupViewController {
                LoggerHelper.log("TOKEN LOGOUT ON LOGIN OR SIGNUP", level: .warning)
            } else if let navController = topController as? UINavigationController,
                (navController.topViewController is LoginViewController
                    || navController.topViewController is SignupViewController) {
                LoggerHelper.log("TOKEN LOGOUT ON LOGIN OR SIGNUP", level: .warning)
            } else {
                _ = SwiftSpinner.show("please_wait".localized)
                
                let logoutUser = [
                    "mobile_device_id": (UIDevice.current.identifierForVendor?.uuidString as AnyObject),
                    "aws_endpoint_id": (AWSPinpointManager.shared.getCurrentEndpointId() as AnyObject)
                ]
                
                FloApiRequest(controller: "v1/logout", method: .post, queryString: nil, data: logoutUser, done: { (_, _) in
                    SwiftSpinner.hide()
                    UserSessionManager.shared.logout()
                    
                    let storyboard = UIStoryboard(name: "Login", bundle: nil)
                    if let login = storyboard.instantiateViewController(
                        withIdentifier: "LoginViewController")as? LoginViewController {
                        login.authErrorMessage = message
                        UIApplication.shared.keyWindow?.rootViewController
                            = UINavigationController(rootViewController: login)
                        UIApplication.shared.keyWindow?.makeKeyAndVisible()
                    }
                }).secureFloRequest()
            }
        }
    }
}
