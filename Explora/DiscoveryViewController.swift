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

class DiscoveryViewController: UIViewController, MGLMapViewDelegate, LoginDelegate {

    weak var mapView: ExploraMapView!

    var userLocation: PFGeoPoint?
    var events: [ExploraEvent]?
    var inSetLocationMode: Bool?
    
    let geoCoder = CLGeocoder()
    
    private var _newEventAddressString: String?
    @IBOutlet weak var setLocationButtonHeight: NSLayoutConstraint!
    
    @IBOutlet weak var eventLocationTextView: UITextView!
    @IBOutlet weak var setLocationStackView: UIStackView!
    @IBOutlet weak var currentLocationButton: UIButton!
    @IBOutlet weak var createEventButton: UIButton!
    @IBOutlet weak var listEventsButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        inSetLocationMode = false
        setLocationStackView.hidden = true

        // initialize the map view
        let styleURL = NSURL(string: "asset://styles/emerald-v8.json")
        mapView = ExploraMapView(frame: view.bounds, styleURL: styleURL)
        mapView.showsUserLocation = true
        mapView.delegate = self
        
        view.addSubview(mapView)
        view.sendSubviewToBack(mapView)

        showCurrentLocationAndEvents()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        currentLocationButton.layer.cornerRadius = 25
        currentLocationButton.clipsToBounds = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func onCreateEventTap(sender: UIButton) {
        if inSetLocationMode == false {
            transitionToCreateEventMode()
        } else {
            transitionOutOfCreateEventMode()
        }
    }
    
    @IBAction func onCurrentLocationTap(sender: UIButton) {
        showCurrentLocationAndEvents()
    }
    
    @IBAction func onSetLocationTap(sender: UIButton) {
        if PFUser.currentUser() != nil {
            let newEvent = ExploraEvent()
            if _newEventAddressString != nil {
                newEvent.eventAddress = _newEventAddressString!
            }
            newEvent.createdBy = PFUser.currentUser()
            newEvent.attendees?.addObject(PFUser.currentUser()!)
            newEvent.eventLocation = PFGeoPoint(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
            
            let storyboard = UIStoryboard(name: "AddEventDet", bundle: nil)
            if let addNavVC = storyboard.instantiateInitialViewController() as? UINavigationController {
                if let addVc = addNavVC.topViewController as? AddEventTableViewController {
                    addVc.event = newEvent
                }
                self.presentViewController(addNavVC, animated: true, completion: nil)
            }

            
        } else {
            let storyboard = UIStoryboard(name: "LoginFlow", bundle: nil)
            if let loginNavVC = storyboard.instantiateInitialViewController() as? UINavigationController {
                if let loginVc = loginNavVC.topViewController as? LoginViewController {
                    loginVc.delegate = self;
                }
                self.presentViewController(loginNavVC, animated: true, completion: nil)
            }
        }

    }
    
    func handleLoginSuccess(user: PFUser) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    

    func transitionToCreateEventMode() {
        inSetLocationMode = true
        
        self.createEventButton.imageView!.image = self.createEventButton.imageView!.image!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        
        UIView.animateWithDuration(0.7, delay: 0.0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0.7, options: .CurveEaseIn, animations: { () -> Void in
            self.createEventButton.transform = CGAffineTransformMakeRotation(CGFloat(M_PI)/4.0 * 3.0)
            self.listEventsButton.transform = CGAffineTransformMakeTranslation(75.0, -75.0)
            self.eventLocationTextView.transform = CGAffineTransformMakeTranslation(0.0, 85.0)
            }, completion: nil)
        
        setLocationStackView.hidden = false
        events = nil
    }
    
    func transitionOutOfCreateEventMode() {
        inSetLocationMode = false
        
        UIView.animateWithDuration(0.7, delay: 0.0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0.7, options: .CurveEaseIn, animations: { () -> Void in
            self.createEventButton.transform = CGAffineTransformMakeRotation(0.0)
            self.listEventsButton.transform = CGAffineTransformMakeTranslation(0.0, 0.0)
            self.eventLocationTextView.transform = CGAffineTransformMakeTranslation(0.0, -85.0)
            }, completion: nil)
        
        setLocationStackView.hidden = true
        showCurrentLocationAndEvents()
    }
    
    func getAddressStringFromCoords(coordinate: CLLocationCoordinate2D) {
        var placemark:CLPlacemark!
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geoCoder.reverseGeocodeLocation(location) { (placemarks, error) -> Void in
            if error != nil {
                print("Reverse Geocode failed with error: \(error!.localizedDescription)")
            } else {
                if placemarks!.count > 0 {
                    placemark = CLPlacemark(placemark: (placemarks?.first)!)
                    
                    let newEventFormattedAddressArray = placemark.addressDictionary?["FormattedAddressLines"] as? NSArray
                    self._newEventAddressString = newEventFormattedAddressArray?.componentsJoinedByString("\n")
                    if let street = placemark.addressDictionary?["Name"] as? NSString {
                        self.updateLocationInTextView(street)
                    }
                }
            }
        }
    }
    
    func updateLocationInTextView(locationString: NSString) {
        let titleString = "Event Location"
        //let locationString = getLocStringFromCoords(newLocCoords)
        
        
        let textString = "\(titleString)\n\(locationString)"
        let attrText = NSMutableAttributedString(string: textString)
        
        let largeFont = UIFont(name: "Arial", size: 16.0)!
        let smallFont = UIFont(name: "Arial", size: 13.0)!
        
        //  Convert textString to NSString because attrText.addAttribute takes an NSRange.
        let titleTextRange = (textString as NSString).rangeOfString(titleString)
        let locationTextRange = (textString as NSString).rangeOfString(locationString as String)
        
        attrText.addAttribute(NSFontAttributeName, value: smallFont, range: titleTextRange)
        attrText.addAttribute(NSForegroundColorAttributeName, value: UIColor.redColor(), range: titleTextRange)
        attrText.addAttribute(NSFontAttributeName, value: largeFont, range: locationTextRange)
        
        eventLocationTextView.attributedText = attrText
        eventLocationTextView.textAlignment = .Center
        
    }
    
    func getEvents(nearGeoPoint: PFGeoPoint) {
        let query = PFQuery(className:ExploraEvent.parseClassName())
        query.whereKey("event_location", nearGeoPoint:nearGeoPoint)
        query.limit = 10
        query.findObjectsInBackgroundWithBlock({ (objects: [PFObject]?, error: NSError?) -> Void in
            if error == nil {
                self.events = objects as? [ExploraEvent]
                print("Successfully retrieved \(objects!.count) events.")
                self.addEventsToMap()
            } else {
                // Log details of the failure
                print("Error: \(error!) \(error!.userInfo)")
            }
        })
    }

    func addEventsToMap() {
        if mapView.annotations != nil {
            mapView.removeAnnotations(mapView.annotations!)
        }
        if events != nil {
            for event in events! {
                mapView.addEventToMap(event)
            }
        }
    }

    func showCurrentLocationAndEvents() {
        let lastKnownLocation = PFUser.currentUser()?.lastKnownLocation
        
        if lastKnownLocation != nil {
            let coordinates = CLLocationCoordinate2DMake(lastKnownLocation!.latitude, lastKnownLocation!.longitude)
            self.mapView.setCenterCoordinate(coordinates, zoomLevel: 12.0, animated: true)
            self.getEvents(lastKnownLocation!)
            PFUser.currentUser()?.updateLocation()
        } else {
        PFGeoPoint.geoPointForCurrentLocationInBackground({ (geopoint: PFGeoPoint?, error: NSError?) -> Void in
                let coordinates = CLLocationCoordinate2DMake(geopoint!.latitude, geopoint!.longitude)
                self.mapView.setCenterCoordinate(coordinates, zoomLevel: 12.0, animated: true)
                self.getAddressStringFromCoords(coordinates)
                self.getEvents(geopoint!)
            })
        }
    }

    // MARK: - Mapbox delegate

    // Use the default marker; see our custom marker example for more information
    func mapView(mapView: MGLMapView, imageForAnnotation annotation: MGLAnnotation) -> MGLAnnotationImage? {
        var annotationImage : MGLAnnotationImage?
        if let exploraAnnotation = annotation as? ExploraPointAnnotation {
            annotationImage = exploraAnnotation.exploraPointAnnotation(imageForEventCategory: mapView)
        }
        return annotationImage
    }
    
    func mapView(mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        if annotation is ExploraPointAnnotation && inSetLocationMode == false {
            return true
        } else {
            return false
        }
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
    
    func mapView(mapView: MGLMapView, regionDidChangeAnimated animated: Bool) {
        if self.inSetLocationMode == true {
            getAddressStringFromCoords(mapView.centerCoordinate)
        }
    }

    @IBAction func listEventsButtonPressed(sender: AnyObject) {
        if PFUser.currentUser() == nil {
            performSegueWithIdentifier("openLoginSegue", sender: sender)
        } else {
            performSegueWithIdentifier("openProfileSegue", sender: sender)
        }
    }
    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "detailSegue" {
            let annotation = sender as! ExploraPointAnnotation
            let vc = segue.destinationViewController as! EventDetailViewController
            vc.event = annotation.event
        } 
    }


}
