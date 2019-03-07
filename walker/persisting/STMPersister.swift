//
//  STMPersister.swift
//  walker
//
//  Created by Edgar Jan Vuicik on 06/03/2019.
//  Copyright © 2019 Sistemiun. All rights reserved.
//

import Squeal

class STMPersister{
    
    private var database: Database
    
    init(dbPath: String) {
        database = try! Database(path: dbPath)
        
        let _ = try? database.execute("PRAGMA TEMP_STORE=MEMORY;")
        
        checkModelMapping()
    }
    
    func mergeSync(entityName: String, attributes:Dictionary<String, Bindable>){
    
        let _ = try? database.insertInto(
            "location",
            values: attributes
        )
        
    }
    
    func checkModelMapping(){
        
        let _ = try? database.createTable("location", definitions: [
            "id TEXT PRIMARY KEY",
            "latitude REAL",
            "latitude REAL"
            ])
        
    }
    
}
