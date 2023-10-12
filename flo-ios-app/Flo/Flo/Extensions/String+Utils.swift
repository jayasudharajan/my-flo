//
//  FloString.swift
//  Flo
//
//  Created by Maurice Bachelor on 5/17/16.
//  Copyright © 2016 Flo Technologies. All rights reserved.
//

import Foundation
import ObjectMapper
import PhoneNumberKit

extension String {
    
    func containsUppercasedLetter() -> Bool {
        if self == self.uppercased() {
            return false
        }
        
        if self == self.lowercased() {
            return false
        }
        
        return true
    }
    
    func containsNumbers() -> Bool {
        let decimalRange = self.rangeOfCharacter(from: .decimalDigits, options: NSString.CompareOptions(), range: nil)
        
        return decimalRange != nil
    }
    
    func isValidEmail() -> Bool {
        let emailRegex = try? NSRegularExpression(pattern: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}", options: .caseInsensitive)
        let match = emailRegex?.firstMatch(in: self, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSRange(location: 0, length: self.count))
        
        return match != nil
    }
    
    func isValidPassword() -> Bool {
        if self.count >= 8 && self.containsUppercasedLetter() && self.containsNumbers() {
            return true
        }
        
        return false
    }
    
    func isValidPhoneNumber() -> (isValid: Bool, number: String?) {
        do {
            let phoneNumberKit = PhoneNumberKit()
            let number = try phoneNumberKit.parse(self)
            return (true, number.numberString) //If code hits the line, library was able to parse the number
        } catch {
            print("Error parsing phone number")
        }
        return (false, nil)
    }
    
    func getCountryCode() -> String? {
        
        do {
            let phoneNumberKit = PhoneNumberKit()
            let number = try phoneNumberKit.parse(self)
            
            return String(describing: number.countryCode)
        } catch {
            print("Error parsing phone number")
        }
        
        return nil
    }
    
    func removeCountryCode() -> String? {
        
        do {
            let phoneNumberKit = PhoneNumberKit()
            let number = try phoneNumberKit.parse(self)
            
            return String(describing: number.nationalNumber)
        } catch {
            print("Error parsing phone number")
        }
        
        return nil
    }
    
    func base64DecodedWithISO() -> String {
        if let decodedData = NSData(base64Encoded: self, options: NSData.Base64DecodingOptions(rawValue: 0)),
            let decodedString = NSString(data: decodedData as Data, encoding: String.Encoding.isoLatin1.rawValue) {
            return decodedString as String
        }
        
        return ""
    }
    
    func convertToObject<M: Mappable>() -> M? {
        if let obj = Mapper<M>().map(JSONString: self) {
            return obj
        }
        
        return nil
    }
    
    func isEmpty() -> Bool {
        return self.trimmingCharacters(in: .whitespacesAndNewlines) == ""
    }
    
    func isLongerThan(_ maxLength: Int) -> Bool {
        return self.count > maxLength
    }
    
    func isShorterThan(_ minLength: Int) -> Bool {
        return self.count < minLength
    }
    
    func toDate(withFormat: String? = nil) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = withFormat ?? "yyyy-MM-dd'T'HH:mm:ss"
        return dateFormatter.date(from: self) ?? Date()//2019-08-14T10:04:20.830Z //2019-05-30T21:06:16Z
    }
}
