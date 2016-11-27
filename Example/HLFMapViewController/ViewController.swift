//
//  ViewController.swift
//  HLFMapViewController
//
//  Created by Peng Wang on 8/3/2015.
//  Copyright (c) 2015 Peng Wang. All rights reserved.
//

import MapKit
import UIKit

import HLFMapViewController

class ViewController: UIViewController, MapViewControllerDelegate {

    @IBOutlet var addressLabel: UILabel!
    @IBOutlet var nameLabel: UILabel!

    var selectedMapItem: MKMapItem? {
        didSet {
            guard selectedMapItem != oldValue else { return }
            updateLocationLabels()
        }
    }

    func updateLocationLabels() {
        if let placemark = selectedMapItem?.placemark {
            let line1 = "\(placemark.subThoroughfare ?? "?") \(placemark.thoroughfare ?? "?")"
            let line2 = "\(placemark.locality ?? "?"), \(placemark.administrativeArea ?? "?") \(placemark.postalCode ?? "?")"
            addressLabel.text = "\(line1)\n\(line2)"
            addressLabel.textColor = UIColor.darkText
        } else {
            addressLabel.text = "Address"
            addressLabel.textColor = UIColor.lightGray
        }
        if let name = selectedMapItem?.name {
            nameLabel.text = name
            nameLabel.textColor = UIColor.darkText
        } else {
            nameLabel.text = "Name"
            nameLabel.textColor = UIColor.lightGray
        }
    }

    @IBAction func showMap(_ sender: Any) {
        let mapViewController = MapViewController(nibName: "MapViewController", bundle: MapViewController.bundle)
        mapViewController.title = NSLocalizedString("Select Nearby Location", comment: "")
        mapViewController.delegate = self
        mapViewController.selectedMapItem = selectedMapItem

        navigationController?.pushViewController(mapViewController, animated: true)
    }

    // MARK: -

    override func viewDidLoad() {
        super.viewDidLoad()
        updateLocationLabels()
    }

    // MARK: -

    func mapViewController(_ mapViewController: MapViewController, didSelectMapItem mapItem: MKMapItem) {
        selectedMapItem = mapItem

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let _ = self.navigationController?.popToViewController(self, animated: true)
        }
    }

    func mapViewController(_ mapViewController: MapViewController, didDeselectMapItem mapItem: MKMapItem) {
        selectedMapItem = nil

        if !mapViewController.hasResults {
            let _ = navigationController?.popToViewController(self, animated: true)
        }
    }

    var customRowHeight: CGFloat?

    func resultsViewController(_ resultsViewController: SearchResultsViewController,
                               didConfigureResultViewCell cell: SearchResultsViewCell, withMapItem mapItem: MKMapItem) {
        let margins = cell.contentView.layoutMargins
        var customMargins = margins
        customMargins.top = 15
        customMargins.bottom = 15
        cell.contentView.layoutMargins = customMargins

        if customRowHeight == nil {
            customRowHeight = resultsViewController.tableView.rowHeight + (
                (customMargins.top - margins.top) + (customMargins.bottom - margins.bottom)
            )
        }
        resultsViewController.tableView.rowHeight = customRowHeight!
    }

}
