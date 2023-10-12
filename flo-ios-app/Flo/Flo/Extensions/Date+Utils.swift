//
//  FloNSDate.swift
//  Flo
//
//  Created by Maurice Bachelor on 7/29/16.
//  Copyright © 2016 Flo Technologies. All rights reserved.
//

import Foundation

internal enum Weekday: String {
    case monday, tuesday, wednesday, thursday, friday, saturday, sunday
}

extension Date {
    
    func getTime() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateFormatter.string(from: self)
    }
    
    func getTimeLocalized() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a"
        dateFormatter.locale = Calendar.current.locale
        return dateFormatter.string(from: self)
    }
    
    func getDay() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E. M/d"
        dateFormatter.locale = Calendar.current.locale
        return dateFormatter.string(from: self)
    }
    
    func getDayHours() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d hh:mm a"
        dateFormatter.locale = Calendar.current.locale
        return dateFormatter.string(from: self)
    }
    
    fileprivate func getFloNotificationDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yy hh:mm a"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateFormatter.string(from: self)
    }
    
    func getRelativeTimeSinceNow() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        let units = Set<Calendar.Component>([.year, .month, .day, .hour, .minute, .second])
        let components = Calendar.current.dateComponents(units, from: self, to: Date())
        let selfComponents = Calendar.current.dateComponents(units, from: Date())
        
        guard
            let year = components.year,
            let month = components.month,
            let day = components.day,
            let hour = components.hour,
            let selfHour = selfComponents.hour,
            let minute = components.minute,
            let second = components.second
        else {
            return self.getFloNotificationDate()
        }
        
        if year > 0 || month > 0 || day > 1 || (day == 1 && hour > selfHour) {
            dateFormatter.dateFormat = "MMMM d "
            var dateString = dateFormatter.string(from: self) + "at".localized
            dateFormatter.dateFormat = " h:mm a"
            dateString += dateFormatter.string(from: self).lowercased()
            return dateString
        } else if day > 0 || hour > selfHour {
            dateFormatter.dateFormat = "h:mm a"
            return "yesterday".localized + ", " + dateFormatter.string(from: self).lowercased()
        } else if hour > 1 {
            dateFormatter.dateFormat = "h:mm a"
            return "today".localized + ", " + dateFormatter.string(from: self).lowercased()
        } else if hour > 0 {
            return "\(hour)h \(minute) " + "min_s_".localized + " " + "ago".localized
        } else if minute > 4 {
            return "\(minute) " + "min_s_".localized + " " + "ago".localized
        } else if minute > 0 {
            return "\(minute) " + "min_s_".localized + " \(second) " + "seconds".localized + " " + "ago".localized
        } else {
            return "\(second) " + "seconds".localized + " " + "ago".localized
        }
    }
    
    func minutes(from date: Date) -> Int {
        return (Calendar.current as NSCalendar).components(.minute, from: date, to: self, options: []).minute!
    }
    
    func seconds(from date: Date) -> Int {
        return (Calendar.current as NSCalendar).components(.second, from: date, to: self, options: []).second!
    }
    
    func days(from date: Date) -> Int {
        return (Calendar.current as NSCalendar).components(.day, from: date, to: self, options: []).day!
    }
    
    func hours(from date: Date) -> Int {
        return (Calendar.current as NSCalendar).components(.hour, from: date, to: self, options: []).hour!
    }
    
    static func isoToDate(_ isodate: String) -> Date? {
        //example isodate: 2016-07-20T12:16:59.779Z
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        if let dateFromString = dateFormatter.date(from: isodate) {
            return dateFromString
        }
        return .none
    }
    
    static func iso8601ToDate(_ isodate: String) -> Date? {
        //example isodate: 2018-05-08T06:49:22.560000
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        switch isodate.count {
        case 19:
            // 2018-05-20T07:30:25
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        case 21:
            // 2018-05-20T07:30:25.1
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.S"
        case 22:
            // 2018-05-20T07:30:25.10
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SS"
        case 23:
            // 2018-05-20T07:30:25.100
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        case 24:
            // 2018-05-20T07:30:25.100Z
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        case 25:
            // 2018-05-20T07:30:25-05:00
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        case 26:
            // 2018-05-20T07:30:25.100100
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        default:
            return nil
        }
        
        if let dateFromString = dateFormatter.date(from: isodate) {
            return dateFromString
        }
        
        return nil
    }
    
    static func isoTimeToDate(_ isodate: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateFormat = "HH:mm:ss"
        
        if let dateFromString = dateFormatter.date(from: isodate) {
            var calendar = Calendar.current
            calendar.timeZone = TimeZone.init(secondsFromGMT: 0) ?? calendar.timeZone
            
            let finalDate = calendar.date(
                bySettingHour: calendar.component(.hour, from: dateFromString),
                minute: calendar.component(.minute, from: dateFromString),
                second: calendar.component(.second, from: dateFromString),
                of: Date()
            )
            
            return finalDate
        }
        
        return nil
    }
    
    func localTimeIntervalFrom00hs() -> Double {
        let calendar = Calendar.current
        
        let hours = calendar.component(.hour, from: self)
        let minutes = calendar.component(.minute, from: self)
        let seconds = calendar.component(.second, from: self)
        
        return Double((hours * 3600) + (minutes * 60) + seconds)
    }
    
    static func epochToDate(_ epoch: Double) -> Date? {
        let date = Date(timeIntervalSince1970: TimeInterval(epoch / 1000))
        return date
    }
    
    func toString(withFormat: String? = nil) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = withFormat ?? "yyyy-MM-dd'T'HH:mm:ss"
        return dateFormatter.string(from: self)
    }
    
    func get(a weekDay: Weekday, searching direction: Calendar.SearchDirection, includingToday: Bool) -> Date {
        let dayName = weekDay.rawValue
        
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        let weekdaysName = calendar.weekdaySymbols.map { $0.lowercased() }
        
        let searchWeekdayIndex = (weekdaysName.firstIndex(of: dayName) ?? 0) + 1
        if includingToday && calendar.component(.weekday, from: self) == searchWeekdayIndex {
            let intervalFrom00hs = self.localTimeIntervalFrom00hs() * -1
            return self.addingTimeInterval(intervalFrom00hs)
        }
        
        var nextDateComponent = DateComponents()
        nextDateComponent.weekday = searchWeekdayIndex
        
        var date = calendar.nextDate(
            after: self,
            matching: nextDateComponent,
            matchingPolicy: .nextTime,
            direction: direction
        )
        
        let intervalFrom00hs = (date?.localTimeIntervalFrom00hs() ?? 0) * -1
        date?.addTimeInterval(intervalFrom00hs)
        
        return date ?? Date()
    }
    
    func firstDayOfMonthFromNow() -> Date {
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.day = 1
        
        if calendar.component(.day, from: self) == 1 {
            let intervalFrom00hs = self.localTimeIntervalFrom00hs() * -1
            return self.addingTimeInterval(intervalFrom00hs)
        }
        
        var date = calendar.nextDate(
            after: self,
            matching: dateComponents,
            matchingPolicy: .nextTime,
            direction: .backward
        )
        
        let intervalFrom00hs = (date?.localTimeIntervalFrom00hs() ?? 0) * -1
        date?.addTimeInterval(intervalFrom00hs)
        
        return date ?? Date()
    }
    
}
