//
//  STMFunctions.swift
//  walker
//
//  Created by Edgar Jan Vuicik on 13/03/2019.
//  Copyright © 2019 Sistemiun. All rights reserved.
//

import Foundation
import Squeal

extension Date {
    
    func toString(withFormat format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        let myString = formatter.string(from: self)
        let yourDate = formatter.date(from: myString)
        formatter.dateFormat = format
        
        return formatter.string(from: yourDate!)
    }
}

extension NSNumber : Bindable {
    
    public func bindToStatement(_ statement:Statement, atIndex index:Int) throws {
        try statement.bindIntValue(Int(truncating: self), atIndex: index)
    }

}

extension NSString : Bindable {
    
    public func bindToStatement(_ statement:Statement, atIndex index:Int) throws {
        try statement.bindStringValue(self as String, atIndex: index)
    }
    
}
