//
//  STMFunctions.swift
//  walker
//
//  Created by Edgar Jan Vuicik on 13/03/2019.
//  Copyright © 2019 Sistemiun. All rights reserved.
//

import Foundation

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

extension Notification.Name {
    static let didCreateLocation = Notification.Name("didCreateLocation")
}
