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
    
    var lastProcessedTimestamp: String {
        get {
            
            if let value = UserDefaults.standard.string(forKey: "lastProcessedTimestamp") {
                return value
            }
            
            return ""
        }
        set(id) {
            UserDefaults.standard.set(id, forKey: "lastProcessedTimestamp")
        }
    }
    
    @IBOutlet var mapView: MKMapView!
    
    var timer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.showsUserLocation = true
        mapView.delegate = self
        mapView.setUserTrackingMode(.followWithHeading, animated: true)
        
        mapView.showsCompass = false
        
        let screenSize: CGRect = UIScreen.main.bounds
        let buttonItem = MKUserTrackingButton(mapView: mapView)
        buttonItem.frame = CGRect(origin: CGPoint(x: screenSize.width - 45, y: 50), size: CGSize(width: 35, height: 35))
        mapView.addSubview(buttonItem)
        let compassItem = MKCompassButton(mapView: mapView)
        compassItem.frame = CGRect(origin: CGPoint(x: screenSize.width - 45, y: 100), size: CGSize(width: 35, height: 35))
        mapView.addSubview(compassItem)
        
        STMLocation.sharedInstance.startTracking()
        drawAllPolylines()
        self.startProcessing().then(self.drawAllPolylines)
        timer = Timer.scheduledTimer(withTimeInterval: STMConstants.AVERAGE_HUMAN_SPEED * STMConstants.ACCURACY, repeats:true, block:{[unowned self] _ in
            self.startProcessing().then(self.drawAllPolylines)
        })

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    var lastDrawnPolygonId = ""
    var coordinates:[Coordinate] = []
    
    func drawAllPolylines(locations:Array<Dictionary<String, Any>>? = nil){
        
        var polygons: [Polygon] = []
        
        let locations = locations ?? STMPersister.sharedInstance.findSync(entityName: "processedLocation", orderBy:"polygonId, ord")
        
        for location in locations {
            
            if lastDrawnPolygonId != location["polygonId"] as! String {
                
                lastDrawnPolygonId = location["polygonId"] as! String
                
                if (coordinates.count > 1) {
                    
                    polygons.append((LineString(points: coordinates)!.buffer(width: STMConstants.POLYGON_SIZE) as! Polygon))
                    
                }
                
                coordinates = []
                
            }
            
            let coordinate = Coordinate(x: CLLocationDegrees(location["longitude"] as! Double), y: CLLocationDegrees(location["latitude"] as! Double))
            
            coordinates.append(coordinate)
            
        }
        
        if (coordinates.count > 1) {
            
            polygons.append((LineString(points: coordinates)!.buffer(width: STMConstants.POLYGON_SIZE) as! Polygon))
            
            coordinates = [coordinates.last!]
            
        }
        
        
        polygons = unionPolygons(polygons: polygons)
        
        for polygon in polygons{
            
            DispatchQueue.main.async() {
                [unowned self] in
                self.mapView.addOverlay(polygon.mapShape() as! MKPolygon)
            }
            
        }
        
    }
    
    var lastProcessedRouteId = ""
    var polygonId = ""
    var processing = false
    
    func startProcessing() -> Promise<Array<Dictionary<String, Any>>>{
        
        return Promise<Array<Dictionary<String, Any>>>(on: .global()) { fulfill, reject in
            
            if (self.processing){
                
                fulfill([])
                
                return
                
            }
            
            self.processing = true
            
            var result:Array<Dictionary<String, Any>> = []
            
            let locations = STMPersister.sharedInstance.findSync(entityName: "location", whereExpr: "timestamp > '\(self.lastProcessedTimestamp)'", orderBy:"timestamp")
                        
            for location in locations{
                
                if self.lastProcessedRouteId != location["routeId"] as! String {
                    
                    self.lastProcessedRouteId = location["routeId"] as! String
                    
                    self.polygonId = UUID().uuidString
                    
                }
                
                let coordinate = CLLocationCoordinate2D(latitude: location["latitude"] as! Double, longitude: location["longitude"] as! Double)
                
                let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: STMConstants.ACCURACY / 2, longitudinalMeters: STMConstants.ACCURACY / 2)
                
                let coordinate1 = CLLocationCoordinate2D(latitude: coordinate.latitude + region.span.latitudeDelta, longitude: coordinate.longitude + region.span.longitudeDelta)
                
                let coordinate2 = CLLocationCoordinate2D(latitude: coordinate.latitude - region.span.latitudeDelta, longitude: coordinate.longitude - region.span.longitudeDelta)
                
                let similar = STMPersister.sharedInstance.findSync(entityName: "processedLocation",
                                                                   whereExpr: "latitude > \(coordinate2.latitude) "
                                                                    + "and latitude < \(coordinate1.latitude) "
                                                                    + "and longitude > \(coordinate2.longitude) "
                                                                    + "and longitude < \(coordinate1.longitude) "
                )
                
                if (similar.count > 0){
                    
                    self.polygonId = UUID().uuidString
                    
                }
                
                if (similar.count == 0){
                                        
                    let atr = ["id": location["id"] as! String,
                               "latitude": location["latitude"] as! Double,
                               "longitude": location["longitude"] as! Double,
                               "timestamp": location["timestamp"] as! String,
                               "ord": location["ord"] as! Int64,
                               "polygonId": self.polygonId] as [String : Any]
                    
                    STMPersister.sharedInstance.mergeSync(entityName: "processedLocation", attributes: atr as! Dictionary<String, Bindable>)
                    
                    result.append(atr)
                    
                }
                
                self.lastProcessedTimestamp = location["timestamp"] as! String
                
            }
            
            self.processing = false
            fulfill(result)
            
            }.catch({ (Error) in
                self.processing = false
            })
        
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
