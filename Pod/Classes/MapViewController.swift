//
//  MapViewController.swift
//  MapViewController
//
//  Created by Peng Wang on 8/3/2015.
//  Copyright (c) 2016 Peng Wang. All rights reserved.
//

import CoreLocation
import MapKit
import UIKit

@objc(HLFMapViewControllerDelegate) public protocol MapViewControllerDelegate: SearchResultsViewControllerDelegate {

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
@objc(HLFMapViewController) public class MapViewController: UIViewController {

    public static var bundle: NSBundle { return NSBundle(forClass: self) }

    /** Not required, but this view controller is pretty useless without a delegate. */
    public weak var delegate: MapViewControllerDelegate?

    @IBOutlet public weak var mapLoadingIndicator: UIActivityIndicatorView!
    @IBOutlet public weak var mapView: MKMapView!

    public private(set) var locationManager: CLLocationManager!
    public private(set) var searchController: UISearchController!
    public private(set) var resultsViewController: SearchResultsViewController!
    public var selectedMapItem: MKMapItem?

    override public func viewDidLoad() {
        super.viewDidLoad()

        self.initLocationManager()
        self.initSearchController()

        // TODO: Handle location loading timeout.
    }

    override public func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        // TODO: Restore searchController state by implementing UIStateRestoring.
    }

    override public func didReceiveMemoryWarning() {
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

        if let placemark = self.selectedMapItem?.placemark, location = placemark.location {
            self.zoomToLocation(location, animated: false)
            self.mapView.showAnnotations([placemark], animated: false)
            self.mapView.selectAnnotation(placemark, animated: false)
        }

        let status = CLLocationManager.authorizationStatus()
        switch status {
        case .NotDetermined:
            self.locationManager.requestAlwaysAuthorization()

        case .AuthorizedAlways, .AuthorizedWhenInUse:
            self.mapView.showsUserLocation = true

        case .Denied, .Restricted:
            self.handleLocationAuthorizationDenial(status)
        }
    }

    /**
     Initializing `searchController` means also setting up and providing
     it our custom `resultsViewController`, as well as updating this view
     controller to handle be the presentation context for it.

     See [Apple docs](https://developer.apple.com/library/ios/samplecode/TableSearch_UISearchController).
     */
    private func initSearchController() {
        self.resultsViewController = SearchResultsViewController(nibName: "SearchResultsViewController", bundle: MapViewController.bundle)
        // self.resultsViewController.debug = true
        self.resultsViewController.delegate = self.delegate
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
    private func handleLocationAuthorizationDenial(status: CLAuthorizationStatus) {
        let message = {
            switch status {
            case .Denied: return "You've denied sharing your location (can be changed in Settings)."
            case .Restricted: return "You're restricted from sharing your location."
            default: fatalError("Unsupported status.")
            }
        }() as String + " You can still find your location manually."

        let alertController = UIAlertController(
            title: "Location Unavailable",
            message: message,
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
            completion?()
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

            guard mapItems != self.resultsViewController.mapItems else { return }
            self.resultsViewController.mapItems = mapItems

            self.mapView.removeAnnotations(self.mapView.annotations)
            let placemarks = mapItems.map { $0.placemark }
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

    public func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        switch status {
        case .NotDetermined: return

        case .AuthorizedAlways, .AuthorizedWhenInUse:
            self.mapView.showsUserLocation = true
            self.mapView.setUserTrackingMode(.None, animated: false)

        case .Denied, .Restricted:
            self.handleLocationAuthorizationDenial(status)
        }
    }

}

// MARK: MKMapViewDelegate

extension MapViewController: MKMapViewDelegate {

    public func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        guard self.selectedMapItem?.placemark == nil else { return }
        guard let location = userLocation.location else { return }

        self.zoomToLocation(location, animated: false)
    }

    public func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        guard !annotation.isEqual(mapView.userLocation) else { return nil }

        let reuseIdentifier = "customAnnotation"
        let dequeued = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseIdentifier)
        guard dequeued == nil else {
            dequeued!.annotation = annotation
            return dequeued
        }

        let pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
        pinView.canShowCallout = true
        pinView.accessibilityValue = annotation.title ?? "An unknown location"

        let selectButton = UIButton(type: .ContactAdd)
        selectButton.accessibilityLabel = "Select address in callout view"
        pinView.rightCalloutAccessoryView = selectButton

        return pinView
    }

    public func mapView(mapView: MKMapView, annotationView view: MKAnnotationView,
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

    public func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

}

// MARK: UISearchControllerDelegate

extension MapViewController: UISearchControllerDelegate {}

// MARK: UISearchResultsUpdating

extension MapViewController: UISearchResultsUpdating {

    public func updateSearchResultsForSearchController(searchController: UISearchController) {
        guard let text = self.searchController.searchBar.text
              where !text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()).characters.isEmpty
              else { return }
        self.searchMapItemsWithQuery(text)
    }

}

// MARK: UITableViewDelegate

extension MapViewController: UITableViewDelegate {

    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard tableView === self.resultsViewController.tableView else { return }

        let mapItem = self.resultsViewController.mapItems[indexPath.row]
        self.selectedMapItem = mapItem

        self.resultsViewController.dismissViewControllerAnimated(true) {

            if let location = mapItem.placemark.location {
                self.zoomToLocation(location, animated: false)
            }
            
            if let annotation = self.findMatchingMapViewAnnotation(mapItem.placemark) {
                // zoomToLocation calls setRegion, which seems to take until the next run loop,
                // and if we don't wait until it's fully done, it may reset the annotation selection.
                dispatch_async(dispatch_get_main_queue()) {
                    self.mapView.selectAnnotation(annotation, animated: false)
                }
            }
            
        }
    }

}
