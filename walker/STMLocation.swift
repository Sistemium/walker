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
    
    func startTracking(){
        
        locationManager.requestAlwaysAuthorization()
        
        locationManager.allowsBackgroundLocationUpdates = true
        
        locationManager.pausesLocationUpdatesAutomatically = false
        
        locationManager.startUpdatingLocation()
        
        locationManager.delegate = self
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print(locations.first!.coordinate)
    }
    
}
