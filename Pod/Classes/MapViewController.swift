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
    func mapViewController(_ mapViewController: MapViewController, didDeselectMapItem mapItem: MKMapItem)

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

    open var pinColor: UIColor?
    open var selectedMapItem: MKMapItem?
    open var zoomedInSpan: CLLocationDegrees = 0.01

    public var hasResults: Bool { return !resultsViewController.mapItems.isEmpty }

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

        mapView.removeAnnotations(removableAnnotations)
    }

    // MARK: Implementation

    fileprivate var queuedSearchQuery: String?
    fileprivate var removableAnnotations: [MKAnnotation] {
        return mapView.annotations.filter(isNonSelectedPlacemark)
    }

    /**
     Small helper necessitated by `CLLocationCoordinate2D` not being
     equatable.
     */
    fileprivate func arePlacemarksEqual(_ a: MKPlacemark, _ b: MKPlacemark) -> Bool {
        return (
            abs(a.coordinate.latitude - b.coordinate.latitude) < DBL_EPSILON &&
            abs(a.coordinate.longitude - b.coordinate.longitude) < DBL_EPSILON
        )
    }

    fileprivate func isNonSelectedPlacemark(_ annotation: MKAnnotation) -> Bool {
        guard let placemark = annotation as? MKPlacemark else { return false }
        guard let selectedPlacemark = self.selectedMapItem?.placemark else { return true }
        return !self.arePlacemarksEqual(placemark, selectedPlacemark)
    }

    /**
    Initializing `locationManager` means getting user location and
    setting `showsUserLocation` to true. Request authorization or
    `handleLocationAuthorizationDenial` if needed.

    See [Getting the User's Location](https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/LocationAwarenessPG/CoreLocation/CoreLocation.html).
    */
    fileprivate func initLocationManager() {
        locationManager = CLLocationManager()
        locationManager.delegate = self

        revealSelectedPlacemark()

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

    fileprivate func revealSelectedPlacemark() {
        guard let placemark = selectedMapItem?.placemark, let location = placemark.location
            else { return }
        isDeferredSelectionEnabled = false
        zoomIn(to: location, animated: false)
        mapView.showAnnotations([placemark], animated: false)
        mapView.selectAnnotation(placemark, animated: false)
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
        mapView.removeAnnotations(removableAnnotations)
        let placemarks = resultsViewController.mapItems.map { $0.placemark }
        mapView.addAnnotations(placemarks.filter(isNonSelectedPlacemark))
        return placemarks
    }

    /**
     Basically converts a location to a region with a hard-coded span no larger than
     `zoomedInSpan`, and sets it on `mapView`. Yet another helper missing from `MKMapView`.
     */
    fileprivate func zoomIn(to location: CLLocation, animated: Bool) {
        revealMapView()

        let degrees = min(mapView.region.span.latitudeDelta, zoomedInSpan)
        let region = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpanMake(degrees, degrees)
        )
        mapView.setRegion(region, animated: animated)
    }

    fileprivate func zoomOut(animated: Bool) {
        let annotations = mapView.annotations.filter(isNonSelectedPlacemark)
        mapView.showAnnotations(annotations, animated: true)
    }

    // MARK: Hack: http://stackoverflow.com/a/38155566/65465

    fileprivate var deferredSelectedPinView: MKPinAnnotationView?
    fileprivate let fragileAssumptiveSelectionDuration: TimeInterval = 0.3
    fileprivate var isDeferredSelectionEnabled = true
    fileprivate var isDeferringSelection: Bool { return deferredSelectedPinView != nil }

    fileprivate func performDeferredSelection(animated: Bool) {
        guard let pinView = deferredSelectedPinView else { return }
        pinView.canShowCallout = true
        let delay = fragileAssumptiveSelectionDuration
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.mapView.deselectAnnotation(pinView.annotation, animated: false)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.mapView.selectAnnotation(pinView.annotation!, animated: animated)
            }
        }
    }

    fileprivate func setUpDeferredSelection(view: MKPinAnnotationView) -> Bool {
        if isDeferredSelectionEnabled {
            deferredSelectedPinView = view
            return true
        } else {
            isDeferredSelectionEnabled = true // Restore to default.
            return false
        }
    }

    fileprivate func tearDownDeferredSelection() -> Bool {
        guard isDeferringSelection else { return false }
        deferredSelectedPinView = nil
        return true
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

final fileprivate class MapPinView: MKPinAnnotationView {

    static let iconFont = UIFont.systemFont(ofSize: 24, weight: UIFontWeightMedium)
    static let reuseIdentifier = "MapPinView"

    var defaultColor = MKPinAnnotationView.redPinColor()
    var isPlacemarkSelected = false {
        didSet {
            if isPlacemarkSelected {
                selectButton.accessibilityLabel = "Deselect address in callout view"
                selectButton.setTitle("－", for: .normal)
                pinTintColor = tintColor
            } else {
                selectButton.accessibilityLabel = "Select address in callout view"
                selectButton.setTitle("＋", for: .normal)
                pinTintColor = defaultColor
            }
            selectButton.sizeToFit()
        }
    }
    var placemark: MKPlacemark { return annotation as! MKPlacemark }

    lazy var detailsButton: UIButton = {
        let button = UIButton(type: .detailDisclosure)
        button.accessibilityLabel = "Show address details in Maps application"
        return button
    }()

    lazy var selectButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = iconFont
        return button
    }()

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setUp()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }

    override func prepareForReuse() {
        isPlacemarkSelected = false
    }

    func setUp() {
        accessibilityValue = placemark.title ?? "An unknown location"
        leftCalloutAccessoryView = detailsButton
        rightCalloutAccessoryView = selectButton
        isPlacemarkSelected = false
    }

}

// MARK: MKMapViewDelegate

extension MapViewController: MKMapViewDelegate {

    open func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        guard selectedMapItem == nil else { return }
        guard mapView.selectedAnnotations.isEmpty else { return }
        guard let location = userLocation.location else { return }

        zoomIn(to: location, animated: false)
    }

    open func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !annotation.isEqual(mapView.userLocation) else { return nil }

        let pinView: MapPinView!
        let reuseIdentifier = String(describing: MapPinView.self)
        if let dequeued = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier) as? MapPinView {
            pinView = dequeued
            pinView.annotation = annotation
        } else {
            pinView = MapPinView(annotation: annotation, reuseIdentifier: reuseIdentifier)
        }

        if (!isDeferredSelectionEnabled) {
            pinView.canShowCallout = true
        }
        if let pinColor = pinColor {
            pinView.defaultColor = pinColor
        }
        if let placemark = annotation as? MKPlacemark, let selectedPlacemark = selectedMapItem?.placemark,
            arePlacemarksEqual(placemark, selectedPlacemark) {
            pinView.isPlacemarkSelected = true
        }

        return pinView
    }

    open func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView,
                      calloutAccessoryControlTapped control: UIControl) {
        guard let button = control as? UIButton else { return }
        guard let view = view as? MapPinView else { return }
        let mapItem = MKMapItem(placemark: view.placemark)
        switch button {
        case view.selectButton:
            if view.isPlacemarkSelected {
                selectedMapItem = nil
                delegate?.mapViewController(self, didDeselectMapItem: mapItem)
            } else {
                selectedMapItem = mapItem
                delegate?.mapViewController(self, didSelectMapItem: mapItem)
            }
            view.isPlacemarkSelected = !view.isPlacemarkSelected
        case view.detailsButton:
            mapItem.openInMaps(launchOptions: nil)
        default: return
        }
    }

    open func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        guard let view = view as? MKPinAnnotationView else { return }
        guard !isDeferringSelection else { return }
        zoomOut(animated: true)
        view.canShowCallout = false
    }

    open func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let view = view as? MKPinAnnotationView else { return }
        guard !tearDownDeferredSelection() else { return }
        guard setUpDeferredSelection(view: view) else { return }
        guard let placemark = view.annotation as? MKPlacemark else { return }
        zoomIn(to: placemark.location!, animated: true)
    }

    open func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        performDeferredSelection(animated: animated)
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
        mapView.removeAnnotations(removableAnnotations)
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
            mapView.removeAnnotations(removableAnnotations)
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

        let annotationToSelect = updateAnnotations()[indexPath.row]
        resultsViewController.dismiss(animated: true) {
            self.mapView.selectAnnotation(annotationToSelect, animated: false)
        }
    }

}
