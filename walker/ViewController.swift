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

class ViewController: UIViewController {
    
    @IBOutlet var mapView: MGLMapView!

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.showsUserLocation = true
        mapView.showsUserHeadingIndicator = true
        mapView.setUserTrackingMode(.followWithHeading, animated: true)
        
        STMLocation.sharedInstance.startTracking()
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
//        var coordsPointer = UnsafeMutablePointer<CLLocationCoordinate2D>.allocate(capacity: Int(polyline.pointCount))
//        polyline.getCoordinates(coordsPointer, range: NSMakeRange(0, Int(polyline.pointCount)))
//
//        // save coords
//        var lineCoords: [CLLocationCoordinate2D] = []
//        for i in 0..<polyline.pointCount {
//            lineCoords.append(coordsPointer[Int(i)])
//        }
//
//        let lineString:LineString = LineString(geometry: lineCoords)
//
//        let bufferLineString = SwiftTurf.buffer(lineString, distance: width, units: .Meters)
//
//        let outer = bufferLineString!.geometry![0]
//        let interiors = bufferLineString?.geometry![1..<bufferLineString!.geometry.count].map({ coords in
//            return MGLPolygon(coordinates: coords, count: UInt(coords.count))
//        })
//        // This polygon is solution
//        self.currentBufferPolygon = MGLPolygon(coordinates: outer, count: UInt(outer.count), interiorPolygons: interiors)
//        mapView.addAnnotation(self.currentBufferPolygon!)
    }


}
