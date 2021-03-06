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
    
    let queue = DispatchQueue(label: "STMPersisterQueue")
    
    private var database: Database
    
    init(dbPath: String) {
        
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]

        database = try! Database(path: documentsPath + "/" + dbPath)
        
        let _ = try? database.execute("PRAGMA TEMP_STORE=MEMORY;")
        
        checkModelMapping()
    }
    
    func findSync(entityName: String, whereExpr:String? = nil, groupBy:String? = nil, orderBy:String? = nil, limit:Int? = nil) -> Array<Dictionary<String, Bindable>>{
        
        var result:Array<Dictionary<String, Bindable>>?
        
        queue.sync {
            result = try! database.selectFrom(entityName, whereExpr:whereExpr, groupBy:groupBy, orderBy:orderBy, limit:limit){
                return $0.dictionaryValue
            }
        }
        
        return result!
        
    }
    
    func mergeSync(entityName: String, attributes:Dictionary<String, Bindable>){
        
        queue.sync {
            
            let _ = try? database.insertInto(
                entityName,
                values: attributes
            )
        }
        
    }
    
    @discardableResult
    func updateSync(entityName: String, columns:[String], values: [Bindable?], whereExpr: String? = nil, parameters: [Bindable?] = []) -> Int {
        
        var result = 0
        
        queue.sync {
            result = try! database.update(entityName, columns: columns, values: values, whereExpr: whereExpr, parameters: parameters) 
        }
        
        return result
        
    }
    
    func checkModelMapping(){
        
        let _ = try? database.createTable("location", definitions: [
            "id TEXT PRIMARY KEY",
            "_id TEXT",
            "ord INTEGER",
            "userId TEXT",
            "latitude REAL",
            "longitude REAL",
            "routeId TEXT",
            "timestamp TEXT"
            ])
        
        let _ = try? database.createTable("processedLocation", definitions: [
            "id TEXT PRIMARY KEY",
            "ord INTEGER",
            "latitude REAL",
            "longitude REAL",
            "polygonId TEXT",
            "timestamp TEXT"
            ])
        
        let _ = try? database.createTable("clientEntity", definitions: [
            "name TEXT PRIMARY KEY",
            "offset INTEGER"
            ])
        
    }
    
}
