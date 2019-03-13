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
    
    func findSync(entityName: String, whereExpr:String? = nil, groupBy:String? = nil, orderBy:String? = nil) -> Array<Dictionary<String, Bindable>>{
        
        return try! database.selectFrom(entityName, whereExpr:whereExpr, groupBy:groupBy, orderBy:orderBy){
            return $0.dictionaryValue
        }
        
    }
    
    func mergeSync(entityName: String, attributes:Dictionary<String, Bindable>){
        
        var _attributes = attributes
        
        _attributes["id"] = UUID().uuidString
        
        _attributes["ts"] = Date().toString(withFormat: "yyyy-MM-dd HH:mm:ss.SSS")
    
        let _ = try? database.insertInto(
            "location",
            values: _attributes
        )
        
    }
    
    func checkModelMapping(){
        
        let _ = try? database.createTable("location", definitions: [
            "id TEXT PRIMARY KEY",
            "latitude REAL",
            "longitude REAL",
            "routeId TEXT",
            "ts TEXT"
            ])
        
    }
    
}
