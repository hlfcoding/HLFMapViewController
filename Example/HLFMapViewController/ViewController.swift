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

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard segue.identifier == "presentMap",
              let navigationController = segue.destinationViewController as? UINavigationController
              else { return }
        let mapViewController = MapViewController(nibName: "MapViewController", bundle: MapViewController.bundle)
        mapViewController.title = NSLocalizedString("Select Nearby Location", comment: "")
        mapViewController.delegate = self
        navigationController.pushViewController(mapViewController, animated: false)
    }

    func mapViewController(mapViewController: MapViewController, didSelectMapItem mapItem: MKMapItem) {
        print(mapItem)
        mapViewController.dismissViewControllerAnimated(true, completion: nil)
    }

}

