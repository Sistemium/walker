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
import FloatingPanel

class ViewController: UIViewController, MKMapViewDelegate, FloatingPanelControllerDelegate {
    
    static var lastProcessedTimestamp: String {
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
    let fpc = FloatingPanelController()
    let tableData = TableData()
    var drawing = false
    var lastProcessedRouteId = ""
    var polygonId = ""
    var processing = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let contentVC = UITableViewController()
        contentVC.tableView.dataSource = tableData
        fpc.delegate = self
        fpc.set(contentViewController: contentVC)
        fpc.track(scrollView: contentVC.tableView)
        fpc.isRemovalInteractionEnabled = true
        
        mapView.showsUserLocation = true
        mapView.delegate = self
        mapView.setUserTrackingMode(.followWithHeading, animated: true)
        mapView.showsCompass = false
        mapView.isPitchEnabled = false
        
        let userTrackingButton = MKUserTrackingButton(mapView: mapView)
        userTrackingButton.layer.backgroundColor = UIColor(white: 1, alpha: 0.8).cgColor
        userTrackingButton.layer.borderColor = UIColor.white.cgColor
        userTrackingButton.layer.cornerRadius = 5
        userTrackingButton.translatesAutoresizingMaskIntoConstraints = false
        
        let compassItem = MKCompassButton(mapView: mapView)
        
        let infoItem = UIButton(type: .infoLight)
        infoItem.contentVerticalAlignment = .center
        infoItem.contentHorizontalAlignment = .center
        infoItem.layer.backgroundColor = UIColor(white: 1, alpha: 0.8).cgColor
        infoItem.layer.borderColor = UIColor.white.cgColor
        infoItem.layer.cornerRadius = 5
        infoItem.translatesAutoresizingMaskIntoConstraints = false
        infoItem.addTarget(self, action: #selector(self.getInfo), for: .touchUpInside)
        
        let stackView = UIStackView(arrangedSubviews: [infoItem, userTrackingButton, compassItem])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 10
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            userTrackingButton.heightAnchor.constraint(equalToConstant: 40),
            userTrackingButton.widthAnchor.constraint(equalToConstant: 40),
            compassItem.heightAnchor.constraint(equalToConstant: 40),
            compassItem.widthAnchor.constraint(equalToConstant: 40),
            infoItem.heightAnchor.constraint(equalToConstant: 40),
            infoItem.widthAnchor.constraint(equalToConstant: 40),
            ])
        
        self.drawAllPolylines(onFlyDraw: true)
        
        STMLocation.sharedInstance.startTracking()
        timer = Timer.scheduledTimer(withTimeInterval: 15, repeats:true, block:{[unowned self] _ in
            self.drawAllPolylines()
            self.startProcessing()
        })
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
    }
    
    func drawAllPolylines(onFlyDraw:Bool = false){
        
        DispatchQueue.global().async {
            [unowned self] in
            
            if self.drawing {
                
                return
                
            }
            
            self.drawing = true
            
            var polygons: [Geometry] = []
            var lastDrawnPolygonId = ""
            var coordinates:[Coordinate] = []
            
            let locations = STMPersister.sharedInstance.findSync(entityName: "processedLocation", orderBy:"polygonId, ord")

            for location in locations {

                if lastDrawnPolygonId != location["polygonId"] as! String {

                    lastDrawnPolygonId = location["polygonId"] as! String

                    if coordinates.count > 1 {

                        polygons.append((LineString(points: coordinates)!.buffer(width: STMConstants.POLYGON_SIZE)!))

                    }

                    coordinates = []
                    
                }

                let coordinate = Coordinate(x: CLLocationDegrees(location["longitude"] as! Double), y: CLLocationDegrees(location["latitude"] as! Double))

                coordinates.append(coordinate)
                
            }

            if coordinates.count > 1 {

                polygons.append((LineString(points: coordinates)!.buffer(width: STMConstants.POLYGON_SIZE) as! Polygon))

            }
            

            self.unionPolygons(polygons: polygons, onFlyDraw: onFlyDraw)
            
            self.drawing = false
            
        }
        
    }
    
    func startProcessing() {
        
        DispatchQueue.global().async {
            [unowned self] in
         
            if self.processing {
                
                return
                
            }
            
            self.processing = true
            
            let locations = STMPersister.sharedInstance.findSync(entityName: "location", whereExpr: "timestamp > '\(ViewController.lastProcessedTimestamp)'", orderBy:"timestamp")
            
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
                
                if similar.count > 0 {
                    
                    self.polygonId = UUID().uuidString
                    
                }
                
                if similar.count == 0 {
                    
                    let atr = ["id": location["id"] as! String,
                               "latitude": location["latitude"] as! Double,
                               "longitude": location["longitude"] as! Double,
                               "timestamp": location["timestamp"] as! String,
                               "ord": location["ord"] as! Int64,
                               "polygonId": self.polygonId] as [String : Any]
                    
                    STMPersister.sharedInstance.mergeSync(entityName: "processedLocation", attributes: atr as! Dictionary<String, Bindable>)
                    
                }
                
                ViewController.lastProcessedTimestamp = location["timestamp"] as! String
                
            }
            
            self.processing = false
            
        }
        
    }
    
    func unionPolygons(polygons:[Geometry], onFlyDraw:Bool = false) {
        
        var _polygons:Geometry? = nil
        
        for polygon in polygons {
            
            if _polygons == nil {
            
                _polygons = polygon
                
            } else {
                
                _polygons = _polygons?.union(polygon)
                
            }
        
            if onFlyDraw {
                
                draw(multiPolygon: _polygons)
                
            }
            
        }
        
        draw(multiPolygon: _polygons)
        
    }
    
    func draw(multiPolygon:Geometry?){
        
        DispatchQueue.main.sync{
            [unowned self] in
            self.mapView.removeOverlays(self.mapView.overlays)
            
            if multiPolygon is MultiPolygon {
                
                for shape in (multiPolygon?.mapShape() as! MKShapesCollection).shapes {
                    
                    self.mapView.addOverlay(shape as! MKPolygon)
                    
                }
                
            } else if multiPolygon != nil {
                
                self.mapView.addOverlay(multiPolygon!.mapShape() as! MKPolygon)
            }
            
        }
        
    }
    
    func randomAnotation(){
        
        let cord = mapView.userLocation.location?.coordinate
        
        if cord == nil {
            
            return
            
        }
        
        mapView.removeAnnotations(mapView.annotations)
        
        let anotation = MKPointAnnotation()
        anotation.coordinate = CLLocationCoordinate2D(latitude: cord!.latitude + Double.random(in: -0.09...0.09), longitude: cord!.longitude + Double.random(in: -0.09...0.09))
        mapView.addAnnotation(anotation)
        
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolygon {
            let polygon = MKPolygonRenderer(overlay: overlay)
//            polygon.fillColor = UIColor(displayP3Red: CGFloat(arc4random()) / CGFloat(UInt32.max), green: CGFloat(arc4random()) / CGFloat(UInt32.max), blue: CGFloat(arc4random()) / CGFloat(UInt32.max), alpha: 0.5)
            polygon.fillColor = .red
            polygon.alpha = 0.5
            return polygon
        }
        
        return MKOverlayRenderer()
    }
    
    @objc func getInfo(){
        
        randomAnotation()
                
        if fpc.parent == nil {
            
            fpc.addPanel(toParent: self)
            
        }
        
        fpc.move(to: .half, animated: true)
        
    }
    
    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout? {
        return MyFloatingPanelLayout()
    }
    
}

class MyFloatingPanelLayout: FloatingPanelLayout {
    public var initialPosition: FloatingPanelPosition {
        return .hidden
    }
    
    public var supportedPositions: Set<FloatingPanelPosition> {
        return [.full, .half, .hidden]
    }
    
    public func insetFor(position: FloatingPanelPosition) -> CGFloat? {
        switch position {
        case .full: return 16.0
        case .half: return 216.0
        default: return nil
        }
    }
}

class TableData:NSObject, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let t = UITableViewCell(style: .subtitle, reuseIdentifier: "test")
        
        if indexPath.row == 0 {
            
            let date = Date().toString(withFormat: STMConstants.TIMELESS_DATE).toDate(dateFormat: STMConstants.TIMELESS_DATE).toString(withFormat: STMConstants.TIME_DATE)
            
            t.textLabel?.text = "Today"
            
            let locations = STMPersister.sharedInstance.findSync(entityName: "location", whereExpr: "timestamp > '\(date.description)'", orderBy:"routeId, ord")
            
            let distance = calculateDistance(locations: locations)
            
            t.detailTextLabel?.text = distance
            
        }
        
        if indexPath.row == 1 {
            
            let date = Date().toString(withFormat: STMConstants.TIMELESS_DATE).toDate(dateFormat: STMConstants.TIMELESS_DATE)
            
            let today = date.toString(withFormat: STMConstants.TIME_DATE)
            
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: date)!.toString(withFormat: STMConstants.TIME_DATE)
            
            t.textLabel?.text = "Yesterday"
            
            let locations = STMPersister.sharedInstance.findSync(entityName: "location", whereExpr: "timestamp < '\(today.description)' and timestamp > '\(yesterday.description)'", orderBy:"routeId, ord")
            
            let distance = calculateDistance(locations: locations)
            
            t.detailTextLabel?.text = distance
            
        }
        
        return t
    }
    
    func calculateDistance(locations:Array<Dictionary<String, Bindable>>) -> String{
        
        var lastProvessed = ""
        var lastLocation:CLLocation? = nil
        var result = 0.0
        
        for location in locations {
            
            let coordinate = CLLocation(latitude: location["latitude"] as! Double, longitude: location["longitude"] as! Double)
            
            let routeId = location["routeId"] as! String
            
            if routeId != lastProvessed {
                
                lastLocation = nil
                
                lastProvessed = routeId
                
            }
            
            if lastLocation != nil {
                
                result += lastLocation!.distance(from: coordinate)
                
                print(lastLocation!.distance(from: coordinate))
                
            }
            
            lastLocation = coordinate
            
        }
        
        return result.formatDistance()
        
    }
    
}
