//
//  DiscoveryViewController.swift
//  Explora
//
//  Created by Daniel Trostli on 10/20/15.
//  Copyright © 2015 explora-codepath. All rights reserved.
//

import UIKit
import Mapbox
import Parse

class DiscoveryViewController: UIViewController, MGLMapViewDelegate {

    @IBOutlet weak var mapView: MGLMapView!

    var userLocation: PFGeoPoint?
    var events: NSArray?

    override func viewDidLoad() {
        super.viewDidLoad()

        // initialize the map view
        let styleURL = NSURL(string: "asset://styles/light-v8.json")
        mapView = MGLMapView(frame: view.bounds, styleURL: styleURL)
        mapView.showsUserLocation = true
        mapView.delegate = self

        getCurrentLocationAndEvents()
        view.addSubview(mapView)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func getEvents() {
        var query = PFQuery(className:ExploraEvent.parseClassName())
        query.whereKey("event_location", nearGeoPoint:userLocation!)
        query.limit = 10
        query.findObjectsInBackgroundWithBlock({ (objects: [PFObject]?, error: NSError?) -> Void in
            if error == nil {
                // The find succeeded.
                self.events = objects as? NSArray
                print("Successfully retrieved \(objects!.count) scores.")
                // Do something with the found objects
                self.addEventsToMap()
                if let objects = objects as? [PFObject]! {
                    for object in objects {
                        print(object.objectId)
                    }
                }
            } else {
                // Log details of the failure
                print("Error: \(error!) \(error!.userInfo)")
            }
        })
    }

    func addEventsToMap() {
        if events != nil {
            for item in events! {
                if let event = item as? ExploraEvent {
                    addEventToMap(event)
                }
            }
        }
    }

    func addEventToMap(event: ExploraEvent){
        if event.eventLocation != nil {
            let pin = ExploraPointAnnotation()
            let geoPoint = event.eventLocation!
            let coordinate = CLLocationCoordinate2DMake(geoPoint.latitude, geoPoint.longitude)
            pin.coordinate = coordinate
            pin.title = "PARTY"
            pin.subtitle = "Lets grab some drinks guys"
            pin.eventId = event.objectId

            self.mapView.addAnnotation(pin)
        }
    }

    // Should be move outside of controller to user model
    func getCurrentLocationAndEvents() {
        PFGeoPoint.geoPointForCurrentLocationInBackground {
            (geoPoint: PFGeoPoint?, error: NSError?) -> Void in
            if error == nil {
                self.userLocation = geoPoint
                let coordinate = CLLocationCoordinate2DMake(geoPoint!.latitude, geoPoint!.longitude)

                self.mapView.setCenterCoordinate(coordinate, zoomLevel: 12.0, animated: true)
                self.getEvents()
            }
        }
    }

    // MARK: - Mapbox delegate

    // Use the default marker; see our custom marker example for more information
    func mapView(mapView: MGLMapView, imageForAnnotation annotation: MGLAnnotation) -> MGLAnnotationImage? {
        var annotationImage = mapView.dequeueReusableAnnotationImageWithIdentifier("people")

        if annotationImage == nil {
            let image = UIImage(named: "people")
            annotationImage = MGLAnnotationImage(image: image!, reuseIdentifier: "people")
        }

        return annotationImage
    }

    func mapView(mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }

    func mapView(mapView: MGLMapView, annotation: MGLAnnotation, calloutAccessoryControlTapped control: UIControl) {

        self.performSegueWithIdentifier("detailSegue", sender: annotation)
    }

    func mapView(mapView: MGLMapView, rightCalloutAccessoryViewForAnnotation annotation: MGLAnnotation) -> UIView? {
        let arrowButton = UIButton.init(type: UIButtonType.System) as UIButton
        arrowButton.frame = CGRectMake(50, 50, 50, 50)

        let arrowImage = UIImage.init(named: "arrow") as UIImage?
        arrowButton.setImage(arrowImage, forState: UIControlState.Normal)

        return arrowButton
    }


    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let annotation = sender as! ExploraPointAnnotation
        let vc = segue.destinationViewController as! EventDetailViewController
        vc.eventId = annotation.eventId
    }


}
