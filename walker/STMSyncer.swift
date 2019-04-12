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
        
//        receiveData()
        
//        sendData()
        
        
    }
    
    private func receiveData(){
        
        var offset:Int = STMPersister.sharedInstance.findSync(entityName: "clientEntity", whereExpr: "name = 'location'").first?["offset"] as? Int ?? 0
        
        let response = Just.get("http://" + STMConstants.API_URL + "/location", params:["userId":UIDevice.current.identifierForVendor!.uuidString], headers: ["x-page-size":"1000", "x-order-by":"cts", "x-offset":"\(offset)"], timeout: STMConstants.HTTP_TIMEOUT)
        
        if (response.ok){
            
            offset += (response.json! as! Array<Any>).count
            
            for location in (response.json! as! Array<Dictionary<String,Any>>) {
                
                print("")
                
            }
         
            let result = STMPersister.sharedInstance.updateSync(entityName: "clientEntity", columns: ["offset"], values: [offset], whereExpr: "name = 'location'")
            
            if (result == 0){
                
                STMPersister.sharedInstance.mergeSync(entityName: "clientEntity", attributes: ["offset": offset, "name": "location"])
                
            }
            
            
        }
        
        print(response.json!)
        
        
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
                        
                        let _ = STMPersister.sharedInstance.updateSync(entityName: "location", columns: ["_id"], values: [id], whereExpr: "id = \(unsyncedData[index]["id"]!)")
                        
                    }
                    
                }
                
            }
            
        } while unsyncedData.count > 0
        
    }

    
}
