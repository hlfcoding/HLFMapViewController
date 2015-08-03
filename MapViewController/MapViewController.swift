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
        }
    }

    private func zoomToLocation(location: CLLocation) {
        let spanDegrees = 0.03
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            ),
            span: MKCoordinateSpanMake(spanDegrees, spanDegrees)
        )

        self.mapView.setRegion(region, animated: true)
    }

}

// MARK: CLLocationManagerDelegate

extension MapViewController: CLLocationManagerDelegate {

    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedWhenInUse || status == .AuthorizedAlways {
            self.mapView.showsUserLocation = true
        }
    }

}

// MARK: MKMapViewDelegate

extension MapViewController: MKMapViewDelegate {

    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        guard let location = userLocation.location else { return }
        self.zoomToLocation(location)
    }

}