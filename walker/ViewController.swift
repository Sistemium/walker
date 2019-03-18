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

let POLYGON_SIZE = 0.0001

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
        
        var polygons: [Polygon] = []
        
        for route in routes {

            let locations = STMPersister.sharedInstance.findSync(entityName: "location", whereExpr:"routeId = '\(route["routeId"] as! String)'")

            var coordinates = locations.map{
                return Coordinate(x: CLLocationDegrees($0["longitude"] as! Double), y: CLLocationDegrees($0["latitude"] as! Double))
            }

            if (coordinates.count == 1){
                
                coordinates.append(coordinates[0])
                
            }
            
            polygons.append((LineString(points: coordinates)!.buffer(width: POLYGON_SIZE) as! Polygon))

        }
        
        polygons = unionPolygons(polygons: polygons)
        
        for polygon in polygons{
            
            DispatchQueue.main.async() {
                [unowned self] in
                self.mapView.addOverlay(polygon.mapShape() as! MKPolygon)
            }
            
        }
        
    }
    
    func unionPolygons(polygons:[Polygon]) -> [Polygon] {
        
        var _polygons = polygons
        
        var index1 = 0
        
        while (index1 < _polygons.count - 1){
            
            var index2 = index1 + 1
            
            while (index2 < _polygons.count){
                
                if (_polygons[index1].intersects(_polygons[index2])
                    && _polygons[index1].area()! < POLYGON_SIZE
                    && _polygons[index2].area()! < POLYGON_SIZE){
                    
                    _polygons[index1] = _polygons[index1].union(_polygons[index2]) as! Polygon
                    
                    _polygons.remove(at: index2)
                    
                    index2 -= 1
                    
                }
                
                index2 += 1
                
            }
            
            index1 += 1
            
        }
        
        return _polygons
        
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolygon {
            let polygon = MKPolygonRenderer(overlay: overlay)
            polygon.fillColor = .red
            polygon.alpha = 0.5
            return polygon
        }
        return MKOverlayRenderer()
    }
    
    

}
