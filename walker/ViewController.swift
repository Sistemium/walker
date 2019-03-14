//
//  ViewController.swift
//  walker
//
//  Created by Edgar Jan Vuicik on 05/03/2019.
//  Copyright © 2019 Sistemiun. All rights reserved.
//

import UIKit
import CoreLocation
import Mapbox
import SwiftTurf

class ViewController: UIViewController, MGLMapViewDelegate {
    
    @IBOutlet var mapView: MGLMapView!
    
    @IBAction func didPressedGeoTrackingButton(_ sender: UIButton) {
        
        if (STMLocation.sharedInstance.tracking){
            
            DispatchQueue.main.async() {
                
                sender.titleLabel?.text = "Start geotracking"
                
            }
            
            STMLocation.sharedInstance.stopTracking()
            
            drawAllPolylines()
            
        } else {
            
            DispatchQueue.main.async() {
                sender.titleLabel?.text = "Stop geotracking"
            }
            
            STMLocation.sharedInstance.startTracking()
            
        }
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.showsUserLocation = true
        mapView.showsUserHeadingIndicator = true
        mapView.setUserTrackingMode(.followWithHeading, animated: true)
        mapView.delegate = self
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        drawAllPolylines()
        
    }

    func drawAllPolylines(){
        
        mapView.removeAnnotations(mapView.annotations ?? [])
        
        let routes = STMPersister.sharedInstance.findSync(entityName: "location", groupBy:"routeId")
        
        for route in routes {
            
            let locations = STMPersister.sharedInstance.findSync(entityName: "location", whereExpr:"routeId = '\(route["routeId"] as! String)'")
            
            let coordinates = locations.map{
                return CLLocationCoordinate2D(latitude: CLLocationDegrees($0["latitude"] as! Double), longitude: CLLocationDegrees($0["longitude"] as! Double))
            }
            
            if (coordinates.count > 1){
                
                let lineString:LineString = LineString(geometry: coordinates)
                
                let bufferLineString = SwiftTurf.buffer(lineString, distance: 30, units: .Meters)
                
                let outer = bufferLineString!.geometry[0]
                let interiors = bufferLineString!.geometry[1..<bufferLineString!.geometry.count].map({ coords in
                    return MGLPolygon(coordinates: coords, count: UInt(coords.count))
                })

                let currentBufferPolygon = MGLPolygon(coordinates: outer, count: UInt(outer.count), interiorPolygons: interiors)
                
                DispatchQueue.main.async() {
                    [unowned self] in

                    self.mapView.addAnnotation(currentBufferPolygon)
                    
                }
                
            }
            
        }
        
    }
    
    func drawAnotationPolylines(){
        
        mapView.removeAnnotations(mapView.annotations ?? [])
        
        let routes = STMPersister.sharedInstance.findSync(entityName: "location", groupBy:"routeId", orderBy:"ts")
        
        for route in routes {
            
            let locations = STMPersister.sharedInstance.findSync(entityName: "location", whereExpr:"routeId = '\(route["routeId"] as! String)'")
            
            let coordinates = locations.map{
                return CLLocationCoordinate2D(latitude: CLLocationDegrees($0["latitude"] as! Double), longitude: CLLocationDegrees($0["longitude"] as! Double))
            }
            
            let polyline = MGLPolyline(coordinates: coordinates, count: UInt(coordinates.count))
            
            polyline.title = route["routeId"] as? String
            
            DispatchQueue.main.async() {
                [unowned self] in
                self.mapView.addAnnotation(polyline)
                
            }
            
        }
        
    }

    
    // MARK: MGLMapViewDelegate
    
    func mapView(_ mapView: MGLMapView, alphaForShapeAnnotation annotation: MGLShape) -> CGFloat {
        // Set the alpha for all shape annotations to 1 (full opacity)
        return 0.5
    }
    
    func mapView(_ mapView: MGLMapView, lineWidthForPolylineAnnotation annotation: MGLPolyline) -> CGFloat {
        // Set the line width for polyline annotations
        return 30.0
    }
    
    func mapView(_ mapView: MGLMapView, strokeColorForShapeAnnotation annotation: MGLShape) -> UIColor {
        
        return .red
        
    }
    
    func mapView(_ mapView: MGLMapView, fillColorForPolygonAnnotation annotation: MGLPolygon) -> UIColor {
        return .red
    }

}
