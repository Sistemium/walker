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

            var coordinates = locations.map{
                return Coordinate(x: CLLocationDegrees($0["longitude"] as! Double), y: CLLocationDegrees($0["latitude"] as! Double))
            }

            if (coordinates.count == 1){
                
                coordinates.append(coordinates[0])
                
            }
            
            let lineString = LineString(points: coordinates)!.buffer(width: 0.001)!.mapShape()!
            
            if let polygon = lineString as? MKPolygon{
                DispatchQueue.main.async() {
                    [unowned self] in
                    self.mapView.addOverlay(polygon)
                }
            }
            
            if let shapesCollection = lineString as? MKShapesCollection{
                let shapes = shapesCollection.shapes
                
                for shape in shapes {
                    if let polygon = shape as? MKPolygon {
                        DispatchQueue.main.async() {
                            [unowned self] in
                            self.mapView.addOverlay(polygon)
                        }
                    }
                }
            }

        }
        
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
