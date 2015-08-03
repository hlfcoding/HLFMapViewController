//
//  ViewController.swift
//  MapViewController
//
//  Created by Peng Wang on 8/3/15.
//  Copyright © 2015 pengxwang. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBAction func showMap(sender: AnyObject) {
        let mapViewController = MapViewController()
        self.presentViewController(mapViewController, animated: true, completion: nil)
    }
}

