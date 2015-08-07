//
//  ViewController.swift
//  MapViewController
//
//  Created by Peng Wang on 8/3/15.
//  Copyright © 2015 pengxwang. All rights reserved.
//

import MapKit
import UIKit

class ViewController: UIViewController, MapViewControllerDelegate {

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard segue.identifier == "presentMap",
              let navigationController = segue.destinationViewController as? UINavigationController,
                  mapViewController = navigationController.topViewController as? MapViewController
              else { return }
        mapViewController.delegate = self
    }

    func mapViewController(mapViewController: MapViewController, didSelectMapItem mapItem: MKMapItem) {
        print(mapItem)
        mapViewController.dismissViewControllerAnimated(true, completion: nil)
    }

}

