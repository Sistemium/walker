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
    let test = TableData()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let contentVC = UITableViewController()
        contentVC.tableView.dataSource = test
        fpc.delegate = self
        fpc.set(contentViewController: contentVC)
        fpc.track(scrollView: contentVC.tableView)
        fpc.isRemovalInteractionEnabled = true
        
        mapView.showsUserLocation = true
        mapView.delegate = self
        mapView.setUserTrackingMode(.followWithHeading, animated: true)
        mapView.showsCompass = false
        
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
        
        DispatchQueue.main.async() {
            [unowned self, polygons] in
        
            for polygon in polygons{
            
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
                
                ViewController.lastProcessedTimestamp = location["timestamp"] as! String
                
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
                
                if (_polygons[index1].intersects(_polygons[index2])){
                    
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
    
    @objc func getInfo(){
        
        if (fpc.parent == nil){
            
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
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let date = Date().toString(withFormat: STMConstants.TIMELESS_DATE).toDate(dateFormat: STMConstants.TIMELESS_DATE).toString(withFormat: STMConstants.TIME_DATE)
        
        let t = UITableViewCell(style: .subtitle, reuseIdentifier: "test")
        t.textLabel?.text = "Today"
        t.detailTextLabel?.text = date.description
        return t
    }
    
}
