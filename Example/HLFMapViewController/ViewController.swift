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

    var selectedMapItem: MKMapItem?

    @IBAction func showMap(_ sender: Any) {
        let mapViewController = MapViewController(nibName: "MapViewController", bundle: MapViewController.bundle)
        mapViewController.title = NSLocalizedString("Select Nearby Location", comment: "")
        mapViewController.delegate = self
        mapViewController.selectedMapItem = selectedMapItem

        navigationController?.pushViewController(mapViewController, animated: true)
    }

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
