//
//  SignUpBuilder.swift
//  Flo
//
//  Created by Matias Paillet on 5/27/19.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

internal class SignUpBuilder {
    
    fileprivate var email: String?
    fileprivate var password: String?
    fileprivate var firstName: String?
    fileprivate var lastName: String?
    fileprivate var phone: String?
    fileprivate var country: FloLocale?
    
    // MARK: - Singleton
    public class var shared: SignUpBuilder {
        struct Static {
            static let instance = SignUpBuilder()
        }
        return Static.instance
    }
    
    // MARK: builder methods
    public func start() {
        self.clean()
    }
    
    public func clean() {
        self.email = nil
        self.password = nil
        self.firstName = nil
        self.lastName = nil
        self.phone = nil
        self.country = nil
    }
    
    public func build() -> (result: [String: AnyObject], error: NSError?) {
        var info = [String: AnyObject]()
        
        let result = self.phone!.isValidPhoneNumber()
        if !result.isValid {
            return (info, NSError.initWithMessage("phone_number_is_invalid".localized))
        }
        self.phone = result.number!.trimmingCharacters(in: .whitespacesAndNewlines)
        
        info["email"] = self.email as AnyObject
        info["password"] = self.password as AnyObject
        info["firstName"] = self.firstName as AnyObject
        info["lastName"] = self.lastName as AnyObject
        info["country"] = self.country?.id as AnyObject
        info["phone"] = self.phone as AnyObject
        return (info, nil)
    }
    
    public func setEmail(_ email: String, andPassword password: String) {
        self.email = email
        self.password = password
    }
    
    public func setFirstName(_ firstName: String, lastName: String, phone: String, andCountry country: FloLocale) {
        self.firstName = firstName
        self.lastName = lastName
        self.phone = phone
        self.country = country
    }
    
}
