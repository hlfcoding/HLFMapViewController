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

@objc protocol MapViewControllerDelegate: NSObjectProtocol {

    /**
    When the 'add' button on a MKAnnotationView callout view is tapped,
    the location represented by the annotation counts as being selected.
    An `MKMapItem` is wrapped around the annotation.
    */
    func mapViewController(mapViewController: MapViewController, didSelectMapItem mapItem: MKMapItem)

}

/**
Map modal for searching and selecting a nearby location. This means it
combines several different Apple API's into one specific (but very
common) solution: `UISearchController`, `MapKit`, `CoreLocation`.
*/
class MapViewController: UIViewController {

    /** Not required, but this view controller is pretty useless without a delegate. */
    weak var delegate: MapViewControllerDelegate?

    @IBOutlet private weak var mapLoadingIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var mapView: MKMapView!

    /** Readonly. */
    var locationManager: CLLocationManager!
    /** Readonly. */
    var searchController: UISearchController!
    /** Readonly. */
    var resultsViewController: SearchResultsViewController!
    /** Readonly. Unused internally for now. */
    var currentPlacemark: MKPlacemark?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.initLocationManager()
        self.initSearchController()

        // TODO: Handle location loading timeout.
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        // TODO: Restore searchController state by implementing UIStateRestoring.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

        self.mapView.removeAnnotations(self.mapView.annotations)
    }

    // MARK: Implementation

    /**
    Initializing `locationManager` means getting user location and
    setting `showsUserLocation` to true. Request authorization or
    `handleLocationAuthorizationDenial` if needed.

    See [Getting the User's Location](https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/LocationAwarenessPG/CoreLocation/CoreLocation.html).
    */
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

    /**
    Initializing `searchController` means also setting up and providing
    it our custom `resultsViewController`, as well as updating this view
    controller to handle be the presentation context for it.

    See [Apple docs](https://developer.apple.com/library/ios/samplecode/TableSearch_UISearchController).
    */
    private func initSearchController() {
        self.resultsViewController = SearchResultsViewController(nibName: "SearchResultsViewController", bundle: nil)
        self.resultsViewController.tableView.delegate = self

        self.searchController = UISearchController(searchResultsController: self.resultsViewController)
        self.searchController.delegate = self
        self.searchController.dimsBackgroundDuringPresentation = false
        self.searchController.hidesNavigationBarDuringPresentation = false
        self.searchController.searchResultsUpdater = self
        self.searchController.searchBar.delegate = self
        self.searchController.searchBar.placeholder = "Search for place or address"
        self.searchController.searchBar.sizeToFit()

        self.definesPresentationContext = true
        self.navigationItem.titleView = self.searchController.searchBar
    }

    /**
    Small helper necessitated by `CLLocationCoordinate2D` not being
    equatable.
    */
    private func findMatchingMapViewAnnotation(reference: MKAnnotation) -> MKAnnotation? {
        var match: MKAnnotation?
        for annotation in self.mapView.annotations
            where annotation.coordinate.latitude == reference.coordinate.latitude &&
                  annotation.coordinate.longitude == reference.coordinate.longitude
        {
            match = annotation
        }
        return match
    }

    /**
    If user denies current location, just present an alert to notify
    them, and show the map in its default state and require manual zoom.
    */
    private func handleLocationAuthorizationDenial() {
        let alertController = UIAlertController(
            title: "Understood",
            message: "You've denied sharing your current location. You can always find your location manually.",
            preferredStyle: .Alert
        )
        alertController.addAction(UIAlertAction(title: "OK", style: .Default) { (action) in
            alertController.dismissViewControllerAnimated(true, completion: nil)
        })
        self.presentViewController(alertController, animated: true, completion: nil)
        self.revealMapView()
        // TODO: Test usability of search results in this state.
    }

    /**
    Stop any indicators and fade in `mapView`, but only if needed.
    */
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

    /**
    Main search handler that makes a `MKLocalSearchRequest` and updates
    `resultsViewController`.

    For now, annotations get updated on `mapView` on search completion,
    despite latter not being visible. This is to avoid doing more work
    on dismissal.

    See [Apple docs](https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/LocationAwarenessPG/EnablingSearch/EnablingSearch.html).
    */
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

            self.resultsViewController.mapItems = mapItems

            self.mapView.removeAnnotations(self.mapView.annotations)
            let placemarks = mapItems.map { (mapItem) -> MKAnnotation in
                return mapItem.placemark
            }
            self.mapView.showAnnotations(placemarks, animated: false)
        }
    }

    /**
    Basically converts a location to a region with a hard-coded span of
    `0.03`, and sets it on `mapView`. Yet another helper missing from
    `MKMapView`.
    */
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

    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        guard !annotation.isEqual(mapView.userLocation) else { return nil }

        let reuseIdentifier = "customAnnotation"
        let dequeued = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseIdentifier)
        guard dequeued == nil else {
            dequeued!.annotation = annotation
            return dequeued
        }

        let view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
        view.canShowCallout = true
        if let title = annotation.title {
            view.accessibilityValue = title
        }
        let selectButton = UIButton(type: .ContactAdd)
        selectButton.accessibilityLabel = "Select address in callout view"
        view.rightCalloutAccessoryView = selectButton

        return view
    }

    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView,
                 calloutAccessoryControlTapped control: UIControl)
    {
        guard let selectButton = control as? UIButton
              where selectButton.buttonType == .ContactAdd
              else { return }
        self.delegate?.mapViewController(self, didSelectMapItem: MKMapItem(placemark: view.annotation as! MKPlacemark))
    }

}

// MARK: UISearchBarDelegate

extension MapViewController: UISearchBarDelegate {

    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

}

// MARK: UISearchControllerDelegate

extension MapViewController: UISearchControllerDelegate {}

// MARK: UISearchResultsUpdating

extension MapViewController: UISearchResultsUpdating {

    func updateSearchResultsForSearchController(searchController: UISearchController) {
        guard let text = self.searchController.searchBar.text
              where !text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()).characters.isEmpty
              else { return }
        self.searchMapItemsWithQuery(text)
    }

}

// MARK: UITableViewDelegate

extension MapViewController: UITableViewDelegate {

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard tableView === self.resultsViewController.tableView else { return }

        let placemark = self.resultsViewController.mapItems[indexPath.row].placemark
        self.currentPlacemark = placemark

        self.resultsViewController.dismissViewControllerAnimated(true) {

            if let location = placemark.location {
                self.zoomToLocation(location, animated: false)
            }

            if let annotation = self.findMatchingMapViewAnnotation(placemark) {
                self.mapView.selectAnnotation(annotation, animated: false)
            }

        }
    }

}
