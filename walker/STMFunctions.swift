//
//  STMFunctions.swift
//  walker
//
//  Created by Edgar Jan Vuicik on 13/03/2019.
//  Copyright © 2019 Sistemiun. All rights reserved.
//

import Foundation
import Squeal
import MapKit

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

extension String {
    
    func toDate(dateFormat:String) -> Date {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        let date = dateFormatter.date(from: self)!
        return date
        
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

extension Double {
    
    func formatDistance() -> String {
        
        let df = MKDistanceFormatter()
        df.unitStyle = .full
        
        return df.string(fromDistance: self)
        
    }
    
}
