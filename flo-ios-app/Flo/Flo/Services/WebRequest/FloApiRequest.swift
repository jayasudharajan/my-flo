//
//  FloApiRequest.swift
//  Flo
//
//  Created by Maurice Bachelor on 3/30/16.
//  Copyright © 2016 Flo Technologies. All rights reserved.
//

import Foundation

internal final class FloApiRequest {
    
    fileprivate var headers: [String: String] = ["User-Agent": "Flo-iOS-1.0"]
    fileprivate let refreshTokenEndpoint = "v1/oauth2/token"
    
    //Real request object, can be either WebRequest or MockedRequest
    fileprivate var internalRequest: FloRequest?
    fileprivate static var shouldMockServices = false
    
    //Semaphore for queuing requests due to re-authentication capabilities.
    fileprivate static let semaphore = DispatchSemaphore(value: 1)
    fileprivate static var queuedRequests: [FloApiRequest] = []
    fileprivate static var alreadyRefreshingToken = false
    fileprivate var rescheduled = true
    
    init(
        controller: String,
        method: RequestMethodType,
        queryString: [String: String]?,
        data: [String: AnyObject]?,
        usingBaseUrl: Bool = true,
        done: @escaping (_ error: FloRequestErrorModel?, _ result: AnyObject?) -> Void
    ) {
        if FloApiRequest.shouldMockServices {
            internalRequest = FloMockedRequest(
                method: method,
                url: controller,
                queryString: queryString,
                data: data,
                requestHeaders: self.headers,
                usingBaseUrl: usingBaseUrl,
                done: done
            )
        } else {
            internalRequest = FloWebRequest(
                method: method,
                url: controller,
                queryString: queryString,
                data: data,
                requestHeaders: self.headers,
                usingBaseUrl: usingBaseUrl,
                done: done
            )
        }
    }
    
    // MARK: Public Methods
    
    public func secureFloRequest() {
        self.checkUserAndRequest()
    }
    
    public func unsecureFloRequest() {
        performRequest()
    }
    
    public class func shouldMockServices(shouldMock: Bool) {
        self.shouldMockServices = shouldMock
    }
    
    public class func demoModeEnabled() -> Bool {
        return self.shouldMockServices
    }
    
    // MARK: Private Methods
    
    fileprivate class func addToQueue(_ request: FloApiRequest) {
        self.semaphore.wait()
        self.queuedRequests.append(request)
        self.semaphore.signal()
    }
    
    fileprivate class func resumeAllPendingRequests() {
        self.semaphore.wait()
        for r in self.queuedRequests {
            r.checkUserAndRequest()
        }
        self.queuedRequests = []
        self.semaphore.signal()
    }
    
    fileprivate func performRequest() {
        self.internalRequest?.request()
    }
    
    fileprivate func checkUserAndRequest() {
        if let auth = UserSessionManager.shared.authorization {
            if auth.tokenOutOfDate() {
                if FloApiRequest.alreadyRefreshingToken {
                    FloApiRequest.addToQueue(self)
                    return
                }

                FloApiRequest.alreadyRefreshingToken = true

                let clientId = PlistHelper.valueForKey("FloApiClientID") as? String ?? ""
                let refreshData = RefreshUserTokenModel(clientId: clientId, refreshToken: auth.refreshJwt).jsonify()

                let originalRequest = self
                _ = FloWebRequest(
                    method: .post,
                    url: self.refreshTokenEndpoint,
                    queryString: nil,
                    data: refreshData,
                    requestHeaders: self.headers,
                    done: { (error, data) in
                    if let e = error {
                        LoggerHelper.log(e.message, level: .error)
                        UserSessionManager.shared.logout()
                        (UIApplication.shared.delegate as? AppDelegate)?.goToLogin()
                        return
                    }
                        
                    if let auth = OAuthModel(data) {
                        UserSessionManager.shared.upsertAuthorization(auth)
                        self.internalRequest?.updateHeader(key: "authorization", value: auth.tokenType + " " + auth.jwt)
                    }
                        
                    originalRequest.performRequest()
                    FloApiRequest.alreadyRefreshingToken = false
                    FloApiRequest.resumeAllPendingRequests()
                }).request()
            } else {
                self.updateHeaderAndRequest(for: auth)
            }
        } else {
            //Add to queue for when there is an authentication and call can be made
            FloApiRequest.addToQueue(self)
        }
    }
    
    fileprivate func updateHeaderAndRequest(for user: OAuthModel? = nil) {
        //If there is a new user model, update user header just in case it got re-authed
        if let notNilUser = user {
            self.internalRequest?.updateHeader(key: "authorization", value: notNilUser.tokenType + " " + notNilUser.jwt)
        }
        self.performRequest()
    }
}
