//
//  FixtureUsageModel.swift
//  Flo
//
//  Created by Nicolás Stefoni on 10/5/18.
//  Copyright © 2018 Flo Technologies. All rights reserved.
//

import SwiftyJSON

internal enum FeedbackCase: Int {
    case correct = 0, wrong = 1, tagged = 2
}

internal class FixtureUsageModel: JsonParsingProtocol {
    
    public let computationId: String
    public let macAddress: String
    public let consumption: Double
    public let type: FixtureType
    public let startDate: Date
    public let endDate: Date
    public let duration: Double
    public var feedback: FixtureUsageFeedback?
    
    required init?(_ object: AnyObject?) {
        let json = JSON(object as? [String: AnyObject] ?? [:])
        
        guard
            let computationId = json["computationId"].string,
            let macAddress = json["macAddress"].string,
            let gallons = json["flow"].double,
            let typeKey = json["fixture"].string,
            let startDateString = json["start"].string,
            let endDateString = json["end"].string,
            let duration = json["duration"].double
        else { return nil }
        
        startDate = Date.iso8601ToDate(startDateString) ?? Date()
        endDate = Date.iso8601ToDate(endDateString) ?? Date()
        
        if let feedbackDictionary = json["feedback"].dictionaryObject {
            feedback = FixtureUsageFeedback(feedbackDictionary as AnyObject)
        }
        
        self.computationId = computationId
        self.macAddress = macAddress
        self.consumption = MeasuresHelper.adjust(gallons, ofType: .volume)
        self.type = FixtureType(rawValue: typeKey) ?? .other
        self.duration = duration
    }
    
    public class func array(_ objects: [Any]?) -> [FixtureUsageModel] {
        var fixtureUsages: [FixtureUsageModel] = []
        
        for object in objects ?? [] {
            if let fixtureUsage = FixtureUsageModel(object as AnyObject) {
                fixtureUsages.append(fixtureUsage)
            }
        }
        
        return fixtureUsages
    }
    
}
    
internal class FixtureUsageFeedback: JsonParsingProtocol {
    
    public let caseType: FeedbackCase
    public let correctFixtureType: FixtureType
    
    required init?(_ object: AnyObject?) {
        let json = JSON(object as? [String: AnyObject] ?? [:])
        
        guard
            let caseValue = json["case"].int,
            let caseType = FeedbackCase(rawValue: caseValue),
            let correctFixtureKey = json["correctFixture"].string
        else { return nil }
        
        self.caseType = caseType
        self.correctFixtureType = FixtureType(rawValue: correctFixtureKey) ?? .other
    }
    
    init(caseType: FeedbackCase, correctFixtureType: FixtureType) {
        self.caseType = caseType
        self.correctFixtureType = correctFixtureType
    }
    
    public func jsonData() -> [String: AnyObject] {
        let feedback: [String: AnyObject] = [
            "case": caseType.rawValue as AnyObject,
            "correctFixture": correctFixtureType.rawValue as AnyObject
        ]
        return ["feedback": feedback as AnyObject]
    }
    
}
