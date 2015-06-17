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

class LocationViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, NSFetchedResultsControllerDelegate{

    @IBOutlet weak var mapView: MKMapView!
    var locationManager: CLLocationManager!
    var sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext!
    var pins: [Pin]!
    
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
        
        pins = fetchAllPins()
        
        var i = 0
        
        for pin in pins {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: pin.lat, longitude: pin.long)
            annotation.title = "default"
            annotation.subtitle = "\(i)"
            i++
            mapView.addAnnotation(annotation)
        }
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
        annotation.title = "default"
        annotation.subtitle = "\(pins.count)"
        
        mapView.addAnnotation(annotation)
        
        let newPin = Pin(longitude: annotation.coordinate.longitude, latitude: annotation.coordinate.latitude, context: sharedContext)
        
        pins.append(newPin)
        
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {

        NSUserDefaults.standardUserDefaults().setDouble(mapView.centerCoordinate.longitude as Double, forKey: "Longitude")
        NSUserDefaults.standardUserDefaults().setDouble(mapView.centerCoordinate.latitude as Double, forKey: "Latitude")
        NSUserDefaults.standardUserDefaults().setDouble(mapView.region.span.longitudeDelta as Double, forKey: "LongDel")
        NSUserDefaults.standardUserDefaults().setDouble(mapView.region.span.latitudeDelta as Double, forKey: "LatDel")
 
    }

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
    
    // MARK: - NSFetchedResultsController
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        fetchRequest.sortDescriptors = []
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
        }()
    
    
    // MARK: - Fetched Results Controller Delegate

    func controllerWillChangeContent(controller: NSFetchedResultsController) {

    }

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
    }
    
    //Add information button to each pin
    func mapView(mapView:MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView {
        let identifier = "MapLocation"

        var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier)
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView.canShowCallout = true
            
            let btn = UIButton.buttonWithType(.DetailDisclosure) as! UIButton
            annotationView.rightCalloutAccessoryView = btn
        }else {
            annotationView.annotation = annotation
        }
        return annotationView
    }
    
    func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, calloutAccessoryControlTapped control: UIControl!){
        let index = view.annotation.subtitle!.toInt()!
        
        let controller = storyboard!.instantiateViewControllerWithIdentifier("PictureViewController") as! PictureViewController
        let pin = pins[index]
        controller.pin = pin
        
        self.navigationController!.pushViewController(controller, animated: true)

    }
    
    
    /*
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

