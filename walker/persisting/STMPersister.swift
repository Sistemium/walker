//
//  STMPersister.swift
//  walker
//
//  Created by Edgar Jan Vuicik on 06/03/2019.
//  Copyright © 2019 Sistemiun. All rights reserved.
//

import Squeal

class STMPersister{
    
    static let sharedInstance = STMPersister(dbPath: "walker.db")
    
    private var database: Database
    
    init(dbPath: String) {
        
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]

        database = try! Database(path: documentsPath + "/" + dbPath)
        
        let _ = try? database.execute("PRAGMA TEMP_STORE=MEMORY;")
        
        checkModelMapping()
    }
    
    func mergeSync(entityName: String, attributes:Dictionary<String, Bindable>){
        
        var _attributes = attributes
        
        _attributes["id"] = UUID().uuidString
    
        let _ = try? database.insertInto(
            "location",
            values: attributes
        )
        
    }
    
    func checkModelMapping(){
        
        let _ = try? database.createTable("location", definitions: [
            "id TEXT PRIMARY KEY",
            "latitude REAL",
            "longitude REAL",
            "routeId TEXT"
            ])
        
    }
    
}
