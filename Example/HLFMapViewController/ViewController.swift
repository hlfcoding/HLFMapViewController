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

    @IBAction func showMap(sender: AnyObject) {
        let mapViewController = MapViewController(nibName: "MapViewController", bundle: MapViewController.bundle)
        mapViewController.title = NSLocalizedString("Select Nearby Location", comment: "")
        mapViewController.delegate = self
        mapViewController.selectedMapItem = self.selectedMapItem

        self.navigationController?.pushViewController(mapViewController, animated: true)
    }

    func mapViewController(mapViewController: MapViewController, didSelectMapItem mapItem: MKMapItem) {
        self.selectedMapItem = mapItem

        self.navigationController?.popToViewController(self, animated: true)
    }

    func resultsViewController(resultsViewController: SearchResultsViewController,
                               didConfigureResultViewCell cell: SearchResultsViewCell, withMapItem mapItem: MKMapItem) {
        resultsViewController.tableView.rowHeight = 50

        var customMargins = cell.contentView.layoutMargins
        customMargins.top = 15.0
        customMargins.bottom = 15.0
        cell.contentView.layoutMargins = customMargins
    }

}
