//
//  STMLocation.swift
//  walker
//
//  Created by Edgar Jan Vuicik on 06/03/2019.
//  Copyright © 2019 Sistemiun. All rights reserved.
//

import CoreLocation

class STMLocation:NSObject, CLLocationManagerDelegate{
    
    static let sharedInstance = STMLocation()
    
    private let locationManager = CLLocationManager()
    
    private var routeId = ""
    
    public private(set) var tracking = false
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.distanceFilter = STMConstants.ACCURACY
//        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
//        locationManager.showsBackgroundLocationIndicator = true
    }
    
    func startTracking(){
        
        routeId = UUID().uuidString
        
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
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locations.forEach{ location in
//            STMLocation.test += 0.0001
            STMPersister.sharedInstance.mergeSync(entityName: "location",
                                                  attributes: ["latitude": location.coordinate.latitude + STMLocation.test,
                                                               "longitude": location.coordinate.longitude,
                                                               "routeId": routeId])
            
//            NotificationCenter.default.post(name: .didCreateLocation, object: nil)
            
            print(locations.first!.coordinate)
        }
    }
    
}
