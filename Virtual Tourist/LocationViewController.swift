//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Mark Zhang on 15/6/10.
//  Copyright (c) 2015年 Mark Zhang. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class LocationViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate{

    @IBOutlet weak var mapView: MKMapView!
    var locationManager: CLLocationManager!
    var sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext!
    var pins: [Pin]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Set map to get long press
        var longPressRecogniser = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
        longPressRecogniser.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPressRecogniser)
        mapView.delegate = self
        
        // Set location manager and its delegate to enable location update tracking
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        
        // Get longtitude and latitude and span from UserDefaults
        var long = NSUserDefaults.standardUserDefaults().doubleForKey("Longitude")
        var lat = NSUserDefaults.standardUserDefaults().doubleForKey("Latitude")
        if long != 0 || lat != 0 {
            var center =  CLLocationCoordinate2D(latitude: lat, longitude: long)
            var span = MKCoordinateSpan(latitudeDelta: NSUserDefaults.standardUserDefaults().doubleForKey("LatDel"), longitudeDelta: NSUserDefaults.standardUserDefaults().doubleForKey("LongDel"))
            mapView.setRegion(MKCoordinateRegion(center: center, span: span), animated: true)
        }
        
        pins = fetchAllPins()
        
        var i = 0
        
        for pin in pins {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: pin.lat, longitude: pin.long)
            annotation.title = "Pin No:"
            
            // Set the pin's number in subtitle so that we can track the pin's number after tapping a pin on the map
            annotation.subtitle = "\(i)"
            i++
            mapView.addAnnotation(annotation)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Add an annotation for long press
    func handleLongPress(getstureRecognizer : UIGestureRecognizer){
        if getstureRecognizer.state != .Began { return }
        
        let touchPoint = getstureRecognizer.locationInView(self.mapView)
        let touchMapCoordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = touchMapCoordinate
        annotation.title = "Pin No:"
        annotation.subtitle = "\(pins.count)"
        
        
        // Add the pin to the map, the Core data and the array
        mapView.addAnnotation(annotation)
        let newPin = Pin(longitude: annotation.coordinate.longitude, latitude: annotation.coordinate.latitude, context: sharedContext)
        pins.append(newPin)
        
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    // Set user default values according to map location update
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {

        NSUserDefaults.standardUserDefaults().setDouble(mapView.centerCoordinate.longitude as Double, forKey: "Longitude")
        NSUserDefaults.standardUserDefaults().setDouble(mapView.centerCoordinate.latitude as Double, forKey: "Latitude")
        NSUserDefaults.standardUserDefaults().setDouble(mapView.region.span.longitudeDelta as Double, forKey: "LongDel")
        NSUserDefaults.standardUserDefaults().setDouble(mapView.region.span.latitudeDelta as Double, forKey: "LatDel")
 
    }
    
    // Fetch the pins to an array instead of using fetchcontroller because it helps locate each Pin with and index in Int format
    func fetchAllPins() -> [Pin] {
        let error: NSErrorPointer = nil
        
        // Create the Fetch Request
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        // Execute the Fetch Request
        let results = sharedContext.executeFetchRequest(fetchRequest, error: error)
        
        // Check for Errors
        if error != nil {
            println("Error in fectchAllActors(): \(error)")
        }
        
        // Return the results, cast to an array of Person objects
        return results as! [Pin]
    }
    
    
    
    // Navigate to the next ViewController
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!)
    {
        let index = view.annotation.subtitle!.toInt()!
        
        let controller = storyboard!.instantiateViewControllerWithIdentifier("PictureViewController") as! PictureViewController
        let pin = pins[index]
        controller.pin = pin
        
        self.navigationController!.pushViewController(controller, animated: true)
    }

}

