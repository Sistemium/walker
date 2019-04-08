//
//  STMSyncer.swift
//  walker
//
//  Created by Edgar Jan Vuicik on 02/04/2019.
//  Copyright © 2019 Sistemiun. All rights reserved.
//

import Just

class STMSyncer{
    
    static let sharedInstance = STMSyncer()
    
    func startSyncing(){
        
        receiveData()
        
        sendData()
        
        
    }
    
    private func receiveData(){
        
        Just.get("http://" + STMConstants.API_URL + "/location", timeout: STMConstants.HTTP_TIMEOUT)
        
        
    }
    
    private func sendData(){
        
        let limit = 1000
        
        var unsyncedData: Array<Dictionary<String, Any>>
        
        repeat{
            
            unsyncedData = STMPersister.sharedInstance.findSync(entityName: "location", whereExpr: "_id is NULL", limit:limit)
            
            if (unsyncedData.count > 0){
                
                let response = Just.post(
                    "http://" + STMConstants.API_URL + "/location",
                    json: unsyncedData,
                    timeout :STMConstants.HTTP_TIMEOUT
                )
                
                if (!response.ok){
                    
                    print("sync Error: \(response.error?.localizedDescription ?? "")")
                    
                    return
                    
                } else {
                    
                    for dic in (response.json! as! Dictionary<String, Any>)["upserted"]! as! Array<Dictionary<String, Any>>{
                        
                        let id = dic["_id"]! as! String
                        
                        let index = dic["index"]! as! Int
                        
                        STMPersister.sharedInstance.updateSync(entityName: "location", columns: ["_id"], values: [id], whereExpr: "id = \(unsyncedData[index]["id"]!)")
                        
                    }
                    
                }
                
            }
            
        } while unsyncedData.count > 0
        
    }

    
}
