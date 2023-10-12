//
//  Validator.swift
//  Flo
//
//  Created by Matias Paillet on 5/29/19.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class Validator {
    
    fileprivate var validations: [NSObject: Bool]
    
    init(objectsToValidate: [NSObject]) {
        validations = [:]
        for obj in objectsToValidate {
            validations[obj] = false
        }
    }
    
    public func allChecksPassed() -> Bool {
        return validations.filter { !$0.value }.count == 0
    }
    
    public func markAsValid(_ obj: NSObject) {
        if validations[obj] != nil {
            validations[obj] = true
        }
    }
    
    public func markAsInvalid(_ obj: NSObject) {
        if validations[obj] != nil {
            validations[obj] = false
        }
    }
}

internal class SingleChoiceValidator {
    
    fileprivate var validations: [FloOptionButton: Bool]
    fileprivate var selectedOption: FloOptionButton?
    
    init(objectsToValidate: [FloOptionButton]) {
        validations = [:]
        for obj in objectsToValidate {
            validations[obj] = false
        }
    }
    
    //Success if one option is selected
    public func allChecksPassed() -> Bool {
        return selectedOption != nil
    }
    
    public func getSelectedOption() -> FloOptionButton? {
        return selectedOption
    }
    
    public func selectOption(_ obj: FloOptionButton) {
        if obj == selectedOption {
            return
        }
        
        if validations[obj] != nil {
            validations[obj] = true
            obj.isSelected = true
            
            //Switche the selected option
            if selectedOption != nil {
              self.unselectOption(selectedOption!)
            }
            selectedOption = obj
        }
    }
    
    public func selectOption(backendIdentifier: String) {
        if backendIdentifier == selectedOption?.backendIdentifier {
            return
        }
        
        for obj in validations where obj.key.backendIdentifier == backendIdentifier {
            validations[obj.key] = true
            obj.key.isSelected = true
            
            //Switche the selected option
            if selectedOption != nil {
                self.unselectOption(selectedOption!)
            }
            selectedOption = obj.key
            break
        }
    }
    
    public func unselectOption(_ obj: FloOptionButton) {
        if validations[obj] != nil {
            validations[obj] = false
            obj.isSelected = false
            
            if selectedOption == obj {
                selectedOption = nil
            }
        }
    }
    
}

internal class MultipleChoiceValidator {
    
    fileprivate var validations: [FloOptionButton: Bool]
    
    init(objectsToValidate: [FloOptionButton]) {
        validations = [:]
        for obj in objectsToValidate {
            validations[obj] = false
        }
    }
    
    //Success if at least one option is selected
    public func allChecksPassed() -> Bool {
        return validations.filter { !$0.value }.count > 0
    }
    
    public func getSelectedOptions() -> [FloOptionButton] {
        return validations.filter { !$0.value }.map { $0.key }
    }
    
    public func selectOption(_ obj: FloOptionButton) {
        if validations[obj] != nil {
            validations[obj] = true
            obj.isSelected = true
        }
    }
    
    public func selectOption(backendIdentifier: String) {
        for obj in validations where obj.key.backendIdentifier == backendIdentifier {
            validations[obj.key] = true
            obj.key.isSelected = true
            break
        }
    }
    
    public func unselectOption(_ obj: FloOptionButton) {
        if validations[obj] != nil {
            validations[obj] = false
            obj.isSelected = false
        }
    }
    
}
