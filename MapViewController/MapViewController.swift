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
    var searchController: UISearchController!
    var resultsViewController: SearchResultsViewController!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.initLocationManager()
        self.initSearchController()
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

    private func initSearchController() {
        self.resultsViewController = SearchResultsViewController(nibName: "SearchResultsViewController", bundle: nil)
        self.resultsViewController.tableView.delegate = self

        self.searchController = UISearchController(searchResultsController: self.resultsViewController)
        self.searchController.delegate = self
        self.searchController.dimsBackgroundDuringPresentation = false
        self.searchController.searchResultsUpdater = self
        self.searchController.searchBar.delegate = self
        self.searchController.searchBar.placeholder = "Search for place or address"
        self.searchController.searchBar.sizeToFit()
        self.navigationItem.titleView = self.searchController.searchBar
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

    private func searchMapItemsWithQuery(query: String) {
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = query
        request.region = self.mapView.region

        let search = MKLocalSearch(request: request)
        search.startWithCompletionHandler { (searchResponse, error) in
            guard let mapItems = searchResponse?.mapItems else {
                print("MKLocalSearch error: \(error)")
                return
            }
            self.mapView.removeAnnotations(self.mapView.annotations)
            let placemarks = mapItems.map { (mapItem) -> MKAnnotation in
                return mapItem.placemark
            }
            self.mapView.showAnnotations(placemarks, animated: true)
            // TODO: Update resultsViewController.
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

// MARK: UISearchBarDelegate

extension MapViewController: UISearchBarDelegate {

    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        guard let text = searchBar.text else { return }
        self.searchMapItemsWithQuery(text)
    }

}

// MARK: UISearchControllerDelegate

extension MapViewController: UISearchControllerDelegate {

}

// MARK: UISearchResultsUpdating

extension MapViewController: UISearchResultsUpdating {

    func updateSearchResultsForSearchController(searchController: UISearchController) {

    }

}

// MARK: UITableViewDelegate

extension MapViewController: UITableViewDelegate {

}
