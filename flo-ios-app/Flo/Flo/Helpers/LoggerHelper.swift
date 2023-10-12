//
//  LoggerHelper.swift
//  Flo
//
//  Created by Nicolás Stefoni on 2/12/16.
//  Copyright © 2016 Flo Technologies. All rights reserved.
//

import Foundation
import SwiftyBeaver
import Embrace

internal class LoggerHelper: SwiftyBeaver {
    
    fileprivate static var initialized = false
    
    public class func initialize() {
        initialized = true
        
        let console = ConsoleDestination()
        console.format = "$Dyyyy-MM-dd'T'HH:mm:ss.SSSZ$d $L $N.$F:$l\n$M $X"
        
        let file = FileDestination()
        file.format = "$Dyyyy-MM-dd'T'HH:mm:ss.SSSZ$d $L $N.$F:$l\n$M $X"
        if let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let appName = PlistHelper.valueForKey("CFBundleName") as? String ?? "FloUnknown"
            let logName = appName.replacingOccurrences(of: " ", with: "").lowercased() + ".log"
            file.logFileURL = url.appendingPathComponent(logName, isDirectory: false)
        }
        
        /* TO REVIEW:
         if the product team decides to add remote logging, we have to move this keys to the plists
         and change them for enterprise ones
         */
        let cloud = SBPlatformDestination(
            appID: "6Jv8Zk",
            appSecret: "uqjDfsjS7Er4wpfmadqdaoqDuluTtkbs",
            encryptionKey: "zi7pzkfpMf3raqcjs5v5yFlGqwa5nenc"
        )
        cloud.format = "$Dyyyy-MM-dd'T'HH:mm:ss.SSSZ$d $L $N.$F:$l\n$M $X"
        
        #if DEBUG
        addDestination(console)
        #else
        addDestination(file)
        addDestination(cloud)
        #endif
    }
    
    public class func log(
        _ message: Any,
        object: Any? = nil,
        level: Level,
        _ file: String = #file,
        _ function: String = #function,
        line: Int = #line
    ) {
        if !initialized {
            initialize()
        }
        
        switch level {
        case .verbose:
            verbose(message, file, function, line: line, context: object)
            #if DEBUG
            if let m = message as? String {
                Embrace.sharedInstance()?.logMessage(m, with: .info, properties: object as? [AnyHashable: Any], takeScreenshot: false)
            }
            #endif
        case .debug:
            debug(message, file, function, line: line, context: object)
            #if DEBUG
            if let m = message as? String {
                Embrace.sharedInstance()?.logMessage(m, with: .info, properties: object as? [AnyHashable: Any], takeScreenshot: false)
            }
            #endif
        case .info:
            info(message, file, function, line: line, context: object)
            #if DEBUG
            if let m = message as? String {
                Embrace.sharedInstance()?.logMessage(m, with: .info, properties: object as? [AnyHashable: Any], takeScreenshot: false)
            }
            #endif
        case .warning:
            warning(message, file, function, line: line, context: object)
            if let m = message as? String {
                Embrace.sharedInstance()?.logMessage(m, with: .warning, properties: object as? [AnyHashable: Any])
            }
        case .error:
            error(message, file, function, line: line, context: object)
            if let m = message as? String {
                Embrace.sharedInstance()?.logMessage(m, with: .error, properties: object as? [AnyHashable: Any])
            }
        }
    }
    
    public class func log(_ exception: Error, _ file: String = #file, _ function: String = #function, line: Int = #line) {
        if !initialized {
            initialize()
        }
        
        error(exception.localizedDescription, file, function, line: line)
        
        //Log in Embrace as well
        Embrace.sharedInstance()?.logHandledError(exception, screenshot: true, properties: [:])
    }
    
    public class func sendLogs() {
        guard
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
            let auth = UserSessionManager.shared.authorization,
            let user = UserSessionManager.shared.user
        else { return }
            
        let appName = PlistHelper.valueForKey("CFBundleName") as? String ?? "FloUnknown"
        let logName = appName.replacingOccurrences(of: " ", with: "").lowercased() + ".log"
        let logsUrl = url.appendingPathComponent(logName, isDirectory: false)
            
        if FileManager.default.fileExists(atPath: logsUrl.path) {
            do {
                let attachment = Attachment(name: logName, mimeType: .textPlain, data: try Data(contentsOf: logsUrl))
                let message = "User ID: " + auth.userId + "\nUser email: " + user.email
                EmailManager.shared.sendEmail(
                    to: FloEmails.support.rawValue,
                    subject: "Flo App Logs",
                    message: message,
                    attachments: [attachment]
                )
            } catch let exception {
                LoggerHelper.log(exception)
            }
        }
    }
    
}
