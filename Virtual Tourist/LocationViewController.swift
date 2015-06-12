//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Mark Zhang on 15/6/10.
//  Copyright (c) 2015年 Mark Zhang. All rights reserved.
//

import UIKit
import MapKit

class LocationViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    var locationManager: CLLocationManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        mapView.delegate = self
        
        var longPressRecogniser = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
        
        longPressRecogniser.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPressRecogniser)
        
        if (CLLocationManager.locationServicesEnabled())
        {
            locationManager = CLLocationManager()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
        }
        
        var long = NSUserDefaults.standardUserDefaults().doubleForKey("Longitude")
        var lat = NSUserDefaults.standardUserDefaults().doubleForKey("Latitude")
        var center =  CLLocationCoordinate2D(latitude: lat, longitude: long)
        var span = MKCoordinateSpan(latitudeDelta: NSUserDefaults.standardUserDefaults().doubleForKey("LatDel"), longitudeDelta: NSUserDefaults.standardUserDefaults().doubleForKey("LongDel"))
        mapView.setRegion(MKCoordinateRegion(center: center, span: span), animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func handleLongPress(getstureRecognizer : UIGestureRecognizer){
        if getstureRecognizer.state != .Began { return }
        
        let touchPoint = getstureRecognizer.locationInView(self.mapView)
        let touchMapCoordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = touchMapCoordinate
        
        mapView.addAnnotation(annotation)
    }
    
    
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        /*let location = locations.last as! CLLocation
        
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))*/
        
        NSUserDefaults.standardUserDefaults().setDouble(mapView.centerCoordinate.longitude as Double, forKey: "Longitude")
        NSUserDefaults.standardUserDefaults().setDouble(mapView.centerCoordinate.latitude as Double, forKey: "Latitude")
        NSUserDefaults.standardUserDefaults().setDouble(mapView.region.span.longitudeDelta as Double, forKey: "LongDel")
        NSUserDefaults.standardUserDefaults().setDouble(mapView.region.span.latitudeDelta as Double, forKey: "LatDel")
 
    }

    
    /*
    func mapView(mapView:MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView {
        let identifier = "MapLocation"
        var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier)
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        }else {
            annotationView.annotation = annotation
        }
        return annotationView
    }
    
    
    func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        switch (newState) {
        case .Starting:
            view.dragState = .Dragging
        case .Ending, .Canceling:
            view.dragState = .None
        default: break
        }
        println("done")
    }*/


}

