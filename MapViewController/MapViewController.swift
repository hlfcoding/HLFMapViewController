//
//  MapViewController.swift
//  MapViewController
//
//  Created by Peng Wang on 8/3/15.
//  Copyright © 2015 pengxwang. All rights reserved.
//

import CoreLocation
import MapKit
import UIKit

class MapViewController: UIViewController {

    @IBOutlet weak var mapLoadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var mapView: MKMapView!

    var locationManager: CLLocationManager!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.initLocationManager()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    private func initLocationManager() {
        self.locationManager = CLLocationManager()
        self.locationManager.delegate = self

        let status = CLLocationManager.authorizationStatus()
        if status == .NotDetermined {
            self.locationManager.requestAlwaysAuthorization()
        } else if status != .Denied {
            self.mapView.showsUserLocation = true
        } else {
            self.handleLocationAuthorizationDenial()
        }
    }

    private func handleLocationAuthorizationDenial() {
        let alertController = UIAlertController(
            title: "Understood",
            message: "You've denied sharing your current location. You can always find your location manually.",
            preferredStyle: .Alert
        )
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) { (action) in
            alertController.dismissViewControllerAnimated(true, completion: nil)
        })
        self.presentViewController(alertController, animated: true, completion: nil)
        self.revealMapView()
    }

    private func revealMapView(completion: (() -> Void)? = nil) {
        guard self.mapView.hidden else { return }

        self.mapLoadingIndicator.stopAnimating()

        self.mapView.alpha = 0.0
        self.mapView.hidden = false
        UIView.animateWithDuration(0.3) {
            self.mapView.alpha = 1.0
            if let completion = completion {
                completion()
            }
        }
    }

    private func zoomToLocation(location: CLLocation, animated: Bool) {
        self.revealMapView()

        let spanDegrees = 0.03
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            ),
            span: MKCoordinateSpanMake(spanDegrees, spanDegrees)
        )

        self.mapView.setRegion(region, animated: animated)
    }

    // MARK: Actions

    @IBAction func dismiss(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

}

// MARK: CLLocationManagerDelegate

extension MapViewController: CLLocationManagerDelegate {

    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedWhenInUse || status == .AuthorizedAlways {
            self.mapView.showsUserLocation = true
        } else {
            self.handleLocationAuthorizationDenial()
        }
    }

}

// MARK: MKMapViewDelegate

extension MapViewController: MKMapViewDelegate {

    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        guard let location = userLocation.location else { return }
        self.zoomToLocation(location, animated: false)
    }

}