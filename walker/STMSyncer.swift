//
//  STMSyncer.swift
//  walker
//
//  Created by Edgar Jan Vuicik on 02/04/2019.
//  Copyright © 2019 Sistemiun. All rights reserved.
//

import Just
import Squeal

class STMSyncer{
    
    static let sharedInstance = STMSyncer()
    
    private var sending = false, receiving = false
    
    func startSyncing(){
        
        if sending || receiving {
            
            return
            
        }
        
        receiveData()
        
        sendData()
    
    }
    
    private func receiveData(){
        
        receiving = true
        
        var offset:Int64 = STMPersister.sharedInstance.findSync(entityName: "clientEntity", whereExpr: "name = 'location'").first?["offset"] as? Int64 ?? 0
        
        //"84DF8774-7BE9-49DF-A6DF-D87304A586C1"
        Just.get(STMConstants.API_URL + "/location", params:["userId":UIDevice.current.identifierForVendor!.uuidString], headers: ["x-page-size":"1000", "x-order-by":"timestamp", "x-offset":"\(offset)"], timeout: STMConstants.HTTP_TIMEOUT){ response in
            
            if !response.ok {
                
                print("sync Error: \(response.error?.localizedDescription ?? "")")
                
                self.receiving = false

                return
                
            }
            
            offset += Int64((response.json! as! Array<Any>).count)
            
            for location in (response.json! as! Array<Dictionary<String,Any>>) {
    
                var _location = location
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = STMConstants.MONGO_DATE
                let date = dateFormatter.date(from: _location["timestamp"] as! String)!.toString(withFormat: STMConstants.TIME_DATE)
                
                _location["timestamp"] = date
                
                _location.removeValue(forKey: "cts")
                
                _location.removeValue(forKey: "ts")
                
                let result = STMPersister.sharedInstance.updateSync(entityName: "location", columns: Array(_location.keys), values: Array(_location.values) as! [Bindable], whereExpr: "id = '\(_location["id"]!)'")
                
                if result == 0 {
                    
                    STMPersister.sharedInstance.mergeSync(entityName: "location", attributes: _location as! Dictionary<String, Bindable>)
                    
                }
                
                if (_location["timestamp"] as! String) < ViewController.lastProcessedTimestamp {
                    
                    ViewController.lastProcessedTimestamp = ""
                    
                }
                
            }
            
            let result = STMPersister.sharedInstance.updateSync(entityName: "clientEntity", columns: ["offset"], values: [offset], whereExpr: "name = 'location'")
            
            if  result == 0 {
                
                STMPersister.sharedInstance.mergeSync(entityName: "clientEntity", attributes: ["offset": offset, "name": "location"])
                
            }
            
            self.receiving = false
            
            if (response.json! as! Array<Dictionary<String,Any>>).count == 1000 {
                
                self.receiveData()
                
            }
            
        }
        
    }
    
    private func sendData(){
        
        sending = true
        
        let limit = 1000
        
        var unsyncedData: Array<Dictionary<String, Any>> = STMPersister.sharedInstance.findSync(entityName: "location", whereExpr: "_id is NULL", orderBy: "timestamp", limit:limit)
            
        if unsyncedData.count > 0 {
            
            Just.post(
                STMConstants.API_URL + "/location",
                json: unsyncedData,
                timeout :STMConstants.HTTP_TIMEOUT
            ){ response in
                
                if !response.ok {
                    
                    print("sync Error: \(response.error?.localizedDescription ?? "")")
                    
                    self.sending = false
                    
                    return
                    
                }
                
                for dic in (response.json! as! Dictionary<String, Any>)["upserted"]! as! Array<Dictionary<String, Any>>{
                    
                    let id = dic["_id"]! as! String
                    
                    let index = dic["index"]! as! Int
                    
                    let _ = STMPersister.sharedInstance.updateSync(entityName: "location", columns: ["_id"], values: [id], whereExpr: "id = '\(unsyncedData[index]["id"]!)'")
                    
                }
                
                self.sending = false
                
            }
            
        }
        
    }

    
}
