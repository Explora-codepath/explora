//
//  EventDetailViewController.swift
//  Explora
//
//  Created by Daniel Trostli on 10/21/15.
//  Copyright © 2015 explora-codepath. All rights reserved.
//

import UIKit
import Mapbox
import Parse

class EventDetailViewController: UIViewController, MGLMapViewDelegate, LoginDelegate {

    var event: ExploraEvent!
    weak var mapView: ExploraMapView!
    
    @IBOutlet weak var eventTitleLabel: UILabel!
    @IBOutlet weak var eventMeetingTimeLabel: UILabel!
    @IBOutlet weak var eventAddressLabel: UILabel!
    @IBOutlet weak var eventDescriptionLabel: UILabel!
    @IBOutlet weak var mapViewContainerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        eventTitleLabel.text = event.eventTitle
        eventDescriptionLabel.text = event.eventDescription
        eventAddressLabel.text = event.eventAddress

        let formatter = NSDateFormatter() //Should be cached somewhere since this is expensive
        formatter.dateStyle = NSDateFormatterStyle.LongStyle
        formatter.timeStyle = .ShortStyle
        
        if event.meetingStartTime != nil {
            let meetingStartTimeString = formatter.stringFromDate(event.meetingStartTime!)
            eventMeetingTimeLabel.text = meetingStartTimeString
        }
        
        // initialize the map view
        let styleURL = NSURL(string: "asset://styles/emerald-v8.json")
        mapView = ExploraMapView(frame: mapViewContainerView.bounds, styleURL: styleURL)
        mapView.scrollEnabled = false
        mapView.delegate = self
        mapView.setCenterCoordinate(event.eventCoordinate!, zoomLevel: 14.0, animated: false)
        mapView.addEventToMap(event)

        mapViewContainerView.addSubview(mapView)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func onJoinTap(sender: UIButton) {
        if PFUser.currentUser() != nil {
            
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

    // MARK: - Login delegate
    
    func handleLoginSuccess(user: PFUser) {
        print(user)
    }
    
    // MARK: - Mapbox delegate

    func mapView(mapView: MGLMapView, imageForAnnotation annotation: MGLAnnotation) -> MGLAnnotationImage? {
        var annotationImage = mapView.dequeueReusableAnnotationImageWithIdentifier("people")
        
        if annotationImage == nil {
            let image = UIImage(named: "people")
            annotationImage = MGLAnnotationImage(image: image!, reuseIdentifier: "people")
        }
        
        return annotationImage
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
