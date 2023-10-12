//
//  FloApiManager.swift
//  Flo
//
//  Created by Julian Astrada on 12/2/16.
//  Copyright © 2016 Flo Technologies. All rights reserved.
//

import Alamofire

internal final class FloApiManager: NSObject {
    
    public var manager: SessionManager!
    
    // MARK: - Singleton
    public class var shared: FloApiManager {
        struct Static {
            static let instance = FloApiManager()
        }
        return Static.instance
    }
    
    override private init() {
        
        super.init()
        
        //SSL-Pinning
        if let certificatesPaths = PlistHelper.valueForKey("SSL-Certificates") as? NSArray {
            var certificates = [SecCertificate]()
            
            for cert in certificatesPaths {
                if let pathToCert = Bundle.main.path(forResource: cert as? String, ofType: "der") {
                    do {
                        let localCertificate = try Data(contentsOf: URL(fileURLWithPath: pathToCert))
                        if let cert = SecCertificateCreateWithData(kCFAllocatorDefault, localCertificate as CFData) {
                            certificates.append(cert)
                        }
                    } catch let exception {
                        LoggerHelper.log(exception)
                    }
                }
            }
            
            let serverTrustPolicy = ServerTrustPolicy.pinCertificates(
                certificates: certificates,
                validateCertificateChain: true,
                validateHost: true
            )
            
            let serverTrustPolicies: [String: ServerTrustPolicy] = [
                (PlistHelper.valueForKey("FloAPIDomain") as? String ?? ""): serverTrustPolicy
            ]
            
            let configuration = URLSessionConfiguration.default
            configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            configuration.timeoutIntervalForRequest = 20
            configuration.urlCache = nil
            
            self.manager = SessionManager(
                configuration: configuration,
                serverTrustPolicyManager: ServerTrustPolicyManager(policies: serverTrustPolicies)
            )
        }
    }
}
