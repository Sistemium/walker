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
import Promises
import Squeal

class ViewController: UIViewController, MKMapViewDelegate {
    
    var lastProcessedId: Int64 {
        get {
            
            if let value = UserDefaults.standard.object(forKey: "lastProcessedId") as? Int64 {
                return value
            }
            
            return 0
        }
        set(id) {
            UserDefaults.standard.set(id, forKey: "lastProcessedId")
        }
    }
    
    @IBOutlet var mapView: MKMapView!
    
    var timer = Timer()

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.showsUserLocation = true
        mapView.setUserTrackingMode(.followWithHeading, animated: true)
        mapView.delegate = self
        STMLocation.sharedInstance.startTracking()
        drawAllPolylines()
        timer = Timer.scheduledTimer(withTimeInterval: STMConstants.AVERAGE_HUMAN_SPEED * STMConstants.ACCURACY * Double(STMConstants.MAX_POLYGON_SIZE), repeats:true, block:{[unowned self] _ in
            self.startProcessing().then(self.drawAllPolylines)
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }

    func drawAllPolylines(routeArray:Array<Dictionary<String, Bindable>>? = nil){
        
        let routes = routeArray ?? STMPersister.sharedInstance.findSync(entityName: "processedLocation", groupBy:"polygonId")
        
        var polygons: [Polygon] = []
        
        for route in routes {

            let locations = STMPersister.sharedInstance.findSync(entityName: "processedLocation", whereExpr:"polygonId = '\(route["polygonId"] as! String)'")

            var coordinates = locations.map{
                return Coordinate(x: CLLocationDegrees($0["longitude"] as! Double), y: CLLocationDegrees($0["latitude"] as! Double))
            }
            
            if (coordinates.count == 1){
                
                coordinates.append(coordinates[0])
                
            }

            polygons.append((LineString(points: coordinates)!.buffer(width: STMConstants.POLYGON_SIZE) as! Polygon))
            
        }
        
        polygons = unionPolygons(polygons: polygons)
        
        for polygon in polygons{
            
            DispatchQueue.main.async() {
                [unowned self] in
                self.mapView.addOverlay(polygon.mapShape() as! MKPolygon)
            }
            
        }
        
    }
    
    func startProcessing() -> Promise<Array<Dictionary<String, String>>>{
        
        return Promise<Array<Dictionary<String, String>>>(on: .global()) { fulfill, reject in
            
            var result:Array<Dictionary<String, String>> = []
            
            let routes = STMPersister.sharedInstance.findSync(entityName: "location", whereExpr: "id > \(self.lastProcessedId)", groupBy:"routeId", orderBy:"id")
            
            for route in routes {
                
                let locations = STMPersister.sharedInstance.findSync(entityName: "location", whereExpr:"routeId = '\(route["routeId"] as! String)'", orderBy:"id")
                
                var polygonId = UUID().uuidString
                
                var polygonCount = 0
                
                for location in locations{
                    
                    let coordinate = CLLocationCoordinate2D(latitude: location["latitude"] as! Double, longitude: location["longitude"] as! Double)
                    
                    let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: STMConstants.ACCURACY, longitudinalMeters: STMConstants.ACCURACY)
                    
                    let coordinate1 = CLLocationCoordinate2D(latitude: coordinate.latitude + region.span.latitudeDelta, longitude: coordinate.longitude + region.span.longitudeDelta)
                    
                    let coordinate2 = CLLocationCoordinate2D(latitude: coordinate.latitude - region.span.latitudeDelta, longitude: coordinate.longitude - region.span.longitudeDelta)
                    
                    let similar = STMPersister.sharedInstance.findSync(entityName: "processedLocation",
                                                         whereExpr: "latitude > \(coordinate2.latitude) "
                                                            + "and latitude < \(coordinate1.latitude) "
                                                            + "and longitude > \(coordinate2.longitude) "
                                                            + "and longitude < \(coordinate1.longitude) "
                    )
                    
                    if (similar.count > 0 || polygonCount >= STMConstants.MAX_POLYGON_SIZE){
                        
                        polygonId = UUID().uuidString
                        
                        polygonCount = 0
                        
                    }
                    
                    if (similar.count == 0){
                        
                        if (polygonCount == 0){
                            
                            result.append(["polygonId": polygonId])
                            
                        }

                        STMPersister.sharedInstance.mergeSync(entityName: "processedLocation", attributes: ["id": location["id"] as! Int64,
                                                                                                            "latitude": location["latitude"] as! Double,
                                                                                                            "longitude": location["longitude"] as! Double,
                                                                                                            "polygonId": polygonId])
                        polygonCount += 1
                        
                    }
                    
                    self.lastProcessedId = location["id"] as! Int64
                    
                }
                
            }
            
            fulfill(result)
                        
        }
        
    }
    
    func unionPolygons(polygons:[Polygon]) -> [Polygon] {

        var _polygons = polygons

        var index1 = 0

        while (index1 < _polygons.count - 1){

            var index2 = index1 + 1

            while (index2 < _polygons.count){

                if (_polygons[index1].intersects(_polygons[index2])
                    && _polygons[index1].area()! < STMConstants.POLYGON_SIZE
                    && _polygons[index2].area()! < STMConstants.POLYGON_SIZE){

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
