//
//  STMLocation.swift
//  walker
//
//  Created by Edgar Jan Vuicik on 06/03/2019.
//  Copyright © 2019 Sistemiun. All rights reserved.
//

import CoreLocation
import UIKit

class STMLocation:NSObject, CLLocationManagerDelegate{
    
    static let sharedInstance = STMLocation()
    
    private let locationManager = CLLocationManager()
    
    private var routeId = ""
    private var ord:Int64 = 0
    
    public private(set) var tracking = false
    
    override init() {
        super.init()
        
        locationManager.delegate = self
        locationManager.distanceFilter = STMConstants.ACCURACY

    }
    
    func startTracking(){
        
        routeId = UUID().uuidString
        
        ord = 0
        
        locationManager.requestAlwaysAuthorization()

        locationManager.allowsBackgroundLocationUpdates = true

        locationManager.pausesLocationUpdatesAutomatically = false
        
        locationManager.startUpdatingLocation()
        
        tracking = true
                
    }
    
    func stopTracking(){
        
        locationManager.stopUpdatingLocation()
        
        tracking = false
        
    }
    
    static var test = 0.0
    
    var lastLocation: CLLocation?
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locations.forEach{ location in
            
            if location.coordinate.latitude == lastLocation?.coordinate.latitude && location.coordinate.longitude == lastLocation?.coordinate.longitude {
                
                return
                
            }
            
            if lastLocation != nil && lastLocation!.distance(from: location) < STMConstants.ACCURACY {
                
                return
                
            }
            
            lastLocation = location
            
//            STMLocation.test -= 0.0001
            
            ord += 1
            
            STMPersister.sharedInstance.mergeSync(entityName: "location",
                                                  attributes: [
                                                    "id": UUID().uuidString,
                                                    "latitude": location.coordinate.latitude + STMLocation.test,
                                                    "userId": UIDevice.current.identifierForVendor!.uuidString,
                                                    "longitude": location.coordinate.longitude + STMLocation.test,
                                                    "routeId": routeId,
                                                    "timestamp": Date().toString(withFormat: STMConstants.TIME_DATE),
                                                    "ord": ord
                ])
            
//            STMSyncer.sharedInstance.startSyncing()
        }
    }
    
}
