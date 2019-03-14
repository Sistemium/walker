//
//  ViewController.swift
//  walker
//
//  Created by Edgar Jan Vuicik on 05/03/2019.
//  Copyright © 2019 Sistemiun. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import GEOSwift

class ViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet var mapView: MKMapView!
    
    @IBAction func didPressedGeoTrackingButton(_ sender: UIButton) {
        
        if (STMLocation.sharedInstance.tracking){
            
            DispatchQueue.main.async() {
                
                sender.setTitle("Start geotracking", for: .normal)
                
            }
            
            STMLocation.sharedInstance.stopTracking()
            
            drawAllPolylines()
            
        } else {
            
            DispatchQueue.main.async() {
                sender.setTitle("Stop geotracking", for: .normal)
            }
            
            STMLocation.sharedInstance.startTracking()
            
        }
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.showsUserLocation = true
        mapView.setUserTrackingMode(.followWithHeading, animated: true)
        mapView.delegate = self
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        drawAllPolylines()
        
    }

    func drawAllPolylines(){
        
        mapView.removeOverlays(mapView.overlays)
        
        let routes = STMPersister.sharedInstance.findSync(entityName: "location", groupBy:"routeId")

        for route in routes {

            let locations = STMPersister.sharedInstance.findSync(entityName: "location", whereExpr:"routeId = '\(route["routeId"] as! String)'")

            let coordinates = locations.map{
                return Coordinate(x: CLLocationDegrees($0["longitude"] as! Double), y: CLLocationDegrees($0["latitude"] as! Double))
            }

            if (coordinates.count > 1){

                let lineString = LineString(points: coordinates)!.mapShape()! as! MKPolyline
                
//                let bufferLineString = SwiftTurf.buffer(lineString, distance: 30, units: .Meters)
//
//                let outer = bufferLineString!.geometry[0]
//                let interiors = bufferLineString!.geometry[1..<bufferLineString!.geometry.count].map({ coords in
//                    return MGLPolygon(coordinates: coords, count: UInt(coords.count))
//                })
//
//                let currentBufferPolygon = MGLPolygon(coordinates: outer, count: UInt(outer.count), interiorPolygons: interiors)
                
                DispatchQueue.main.async() {
                    [unowned self] in

                    self.mapView.addOverlay(lineString)
                    
                }

            }

        }
        
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let lineView = MKPolylineRenderer(overlay: overlay)
            lineView.strokeColor = UIColor.red
            return lineView
        }
        return MKOverlayRenderer()
    }
    
    

}
