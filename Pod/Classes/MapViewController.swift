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

@objc(HLFMapViewControllerDelegate)
public protocol MapViewControllerDelegate: SearchResultsViewControllerDelegate {

    /**
     When the 'add' button on a MKAnnotationView callout view is tapped,
     the location represented by the annotation counts as being selected.
     An `MKMapItem` is wrapped around the annotation.
     */
    func mapViewController(_ mapViewController: MapViewController, didSelectMapItem mapItem: MKMapItem)

}

/**
 Map modal for searching and selecting a nearby location. This means it
 combines several different Apple API's into one specific (but very
 common) solution: `UISearchController`, `MapKit`, `CoreLocation`.
 */
@objc(HLFMapViewController)
open class MapViewController: UIViewController {

    open static var bundle: Bundle { return Bundle(for: self) }

    /** Not required, but this view controller is pretty useless without a delegate. */
    open weak var delegate: MapViewControllerDelegate?

    @IBOutlet open weak var mapLoadingIndicator: UIActivityIndicatorView!
    @IBOutlet open weak var mapView: MKMapView!

    open fileprivate(set) var locationManager: CLLocationManager!
    open fileprivate(set) var searchController: UISearchController!
    open fileprivate(set) var resultsViewController: SearchResultsViewController!
    open var selectedMapItem: MKMapItem?

    var queuedSearchQuery: String?

    override open func viewDidLoad() {
        super.viewDidLoad()

        initLocationManager()
        initSearchController()
        mapLoadingIndicator.color = view.tintColor

        // TODO: Handle location loading timeout.
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // TODO: Restore searchController state by implementing UIStateRestoring.
    }

    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

        mapView.removeAnnotations(mapView.annotations)
    }

    // MARK: Implementation

    /**
    Initializing `locationManager` means getting user location and
    setting `showsUserLocation` to true. Request authorization or
    `handleLocationAuthorizationDenial` if needed.

    See [Getting the User's Location](https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/LocationAwarenessPG/CoreLocation/CoreLocation.html).
    */
    fileprivate func initLocationManager() {
        locationManager = CLLocationManager()
        locationManager.delegate = self

        if let placemark = selectedMapItem?.placemark, let location = placemark.location {
            zoom(to: location, animated: false)
            mapView.showAnnotations([placemark], animated: false)
            mapView.selectAnnotation(placemark, animated: false)
        }

        let status = CLLocationManager.authorizationStatus()
        switch status {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()

        case .authorizedAlways, .authorizedWhenInUse:
            mapView.showsUserLocation = true

        case .denied, .restricted:
            handleLocationAuthorizationDenial(with: status)
        }
    }

    /**
     Initializing `searchController` means also setting up and providing
     it our custom `resultsViewController`, as well as updating this view
     controller to handle be the presentation context for it.

     See [Apple docs](https://developer.apple.com/library/ios/samplecode/TableSearch_UISearchController).
     */
    fileprivate func initSearchController() {
        resultsViewController = SearchResultsViewController(
            nibName: "SearchResultsViewController", bundle: MapViewController.bundle
        )
        // resultsViewController.debug = true
        resultsViewController.delegate = delegate
        resultsViewController.tableView.delegate = self

        searchController = UISearchController(searchResultsController: resultsViewController)
        searchController.delegate = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = "Search for place or address"
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.sizeToFit()
        searchController.loadViewIfNeeded()

        definesPresentationContext = true
        navigationItem.titleView = searchController.searchBar
    }

    /**
     Small helper necessitated by `CLLocationCoordinate2D` not being
     equatable.
     */
    fileprivate func findMatchingMapViewAnnotation(for reference: MKAnnotation) -> MKAnnotation? {
        var match: MKAnnotation?
        for annotation in mapView.annotations
            where annotation.coordinate.latitude == reference.coordinate.latitude &&
                  annotation.coordinate.longitude == reference.coordinate.longitude {
            match = annotation
        }
        return match
    }

    /**
     If user denies current location, just present an alert to notify
     them, and show the map in its default state and require manual zoom.
     */
    fileprivate func handleLocationAuthorizationDenial(with status: CLAuthorizationStatus) {
        let message = {
            switch status {
            case .denied: return "You've denied sharing your location (can be changed in Settings)."
            case .restricted: return "You're restricted from sharing your location."
            default: fatalError("Unsupported status.")
            }
        }() as String + " You can still find your location manually."

        let alertController = UIAlertController(
            title: "Location Unavailable",
            message: message,
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "OK", style: .default) { (action) in
            alertController.dismiss(animated: true, completion: nil)
        })

        present(alertController, animated: true, completion: nil)
        revealMapView()
        // TODO: Test usability of search results in this state.
    }

    /**
     Stop any indicators and fade in `mapView`, but only if needed.
     */
    fileprivate func revealMapView(completion: (() -> Void)? = nil) {
        guard mapView.isHidden else { return }

        mapLoadingIndicator.stopAnimating()

        mapView.alpha = 0
        mapView.isHidden = false
        UIView.animate(withDuration: 0.3, animations: {
            self.mapView.alpha = 1
            completion?()
        }) 
    }

    /**
     Main search handler that makes a `MKLocalSearchRequest` and updates
     `resultsViewController`.

     See [Apple docs](https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/LocationAwarenessPG/EnablingSearch/EnablingSearch.html).
     */
    @objc fileprivate func searchMapItems(query: String) {
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = query
        request.region = mapView.region

        let search = MKLocalSearch(request: request)
        search.start { (searchResponse, error) in
            guard let mapItems = searchResponse?.mapItems else {
                print("MKLocalSearch error: \(error)")
                return
            }

            guard mapItems != self.resultsViewController.mapItems else { return }
            self.resultsViewController.mapItems = mapItems
        }
    }

    /**
     Simply reloads. But it returns the new annotations because using `MKMapView.annotations`
     or `MKMapItem.placemark` seems to yield equal but new references unsuited for selecting.
     Doing so would fail with a warning about 'un-added' annotations.
     */
    fileprivate func updateAnnotations() -> [MKAnnotation] {
        mapView.removeAnnotations(mapView.annotations)
        let annotations = resultsViewController.mapItems.map { $0.placemark }
        mapView.addAnnotations(annotations)
        return annotations
    }

    /**
     Basically converts a location to a region with a hard-coded span of
     `0.03`, and sets it on `mapView`. Yet another helper missing from
     `MKMapView`.
     */
    fileprivate func zoom(to location: CLLocation, animated: Bool) {
        revealMapView()

        let spanDegrees = 0.03
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            ),
            span: MKCoordinateSpanMake(spanDegrees, spanDegrees)
        )

        mapView.setRegion(region, animated: animated)
    }

    // MARK: Actions

    @IBAction func dismiss(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

}

// MARK: CLLocationManagerDelegate

extension MapViewController: CLLocationManagerDelegate {

    open func locationManager(_ manager: CLLocationManager,
                              didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined: return

        case .authorizedAlways, .authorizedWhenInUse:
            mapView.showsUserLocation = true
            mapView.setUserTrackingMode(.none, animated: false)

        case .denied, .restricted:
            handleLocationAuthorizationDenial(with: status)
        }
    }

}

// MARK: MKMapViewDelegate

extension MapViewController: MKMapViewDelegate {

    open func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        guard selectedMapItem?.placemark == nil else { return }
        guard let location = userLocation.location else { return }

        zoom(to: location, animated: false)
    }

    open func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !annotation.isEqual(mapView.userLocation) else { return nil }

        let reuseIdentifier = "customAnnotation"
        let dequeued = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
        guard dequeued == nil else {
            dequeued!.annotation = annotation
            return dequeued
        }

        let pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
        pinView.canShowCallout = true
        pinView.accessibilityValue = annotation.title ?? "An unknown location"

        let selectButton = UIButton(type: .contactAdd)
        selectButton.accessibilityLabel = "Select address in callout view"
        pinView.rightCalloutAccessoryView = selectButton

        let detailsButton = UIButton(type: .detailDisclosure)
        detailsButton.accessibilityLabel = "Show address details in Maps application"
        pinView.leftCalloutAccessoryView = detailsButton

        return pinView
    }

    open func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView,
                      calloutAccessoryControlTapped control: UIControl) {
        guard let button = control as? UIButton else { return }
        let mapItem = MKMapItem(placemark: view.annotation as! MKPlacemark)
        switch button.buttonType {
        case .contactAdd:
            delegate?.mapViewController(self, didSelectMapItem: mapItem)
        case .detailDisclosure:
            mapItem.openInMaps(launchOptions: nil)
        default: return
        }
    }

    open func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        guard view is MKPinAnnotationView else { return }
        mapView.showAnnotations(mapView.annotations, animated: false)
    }

    open func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let placemark = view.annotation as? MKPlacemark else { return }
        zoom(to: placemark.location!, animated: false)
    }

}

// MARK: UISearchBarDelegate

extension MapViewController: UISearchBarDelegate {

    open func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        guard queuedSearchQuery == nil, let query = preparedSearchQuery, !query.isEmpty
            else { return }
        searchMapItems(query: query)
    }

    open func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        mapView.removeAnnotations(mapView.annotations)
    }

}

// MARK: UISearchControllerDelegate

extension MapViewController: UISearchControllerDelegate {}

// MARK: UISearchResultsUpdating

extension MapViewController: UISearchResultsUpdating {

    var preparedSearchQuery: String? {
        guard let text = searchController.searchBar.text else { return nil }
        return text.trimmingCharacters(in: .whitespaces)
    }

    open func updateSearchResults(for searchController: UISearchController) {
        guard let query = preparedSearchQuery else { return }
        guard !query.isEmpty else {
            mapView.removeAnnotations(mapView.annotations)
            return
        }

        let selector = #selector(searchMapItems(query:))
        NSObject.cancelPreviousPerformRequests(
            withTarget: self, selector: selector, object: queuedSearchQuery
        )
        queuedSearchQuery = query
        perform(selector, with: query, afterDelay: 0.6)
    }

}

// MARK: UITableViewDelegate

extension MapViewController: UITableViewDelegate {

    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView === resultsViewController.tableView else { return }

        selectedMapItem = resultsViewController.mapItems[indexPath.row]
        let annotationToSelect = updateAnnotations()[indexPath.row]

        resultsViewController.dismiss(animated: true) {
            self.mapView.selectAnnotation(annotationToSelect, animated: false)
        }
    }

}
