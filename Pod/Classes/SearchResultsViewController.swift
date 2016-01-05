//
//  SearchResultsViewController.swift
//  MapViewController
//
//  Created by Peng Wang on 8/6/2015.
//  Copyright © 2015 Peng Wang. All rights reserved.
//

import Contacts
import MapKit
import UIKit

@objc(HLFSearchResultsViewController) public class SearchResultsViewController: UITableViewController {

    let cellReuseIdentifier = "searchResult"

    public var mapItems: [MKMapItem] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.registerClass(SearchResultsViewCell.self, forCellReuseIdentifier: self.cellReuseIdentifier)
        self.tableView.registerNib(UINib(nibName: "SearchResultsViewCell", bundle: MapViewController.bundle), forCellReuseIdentifier: self.cellReuseIdentifier)
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

        self.mapItems = []
    }

    // MARK: UITableViewDataSource

    override public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.mapItems.count
    }

    override public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(self.cellReuseIdentifier, forIndexPath: indexPath)
        let mapItem = self.mapItems[indexPath.row]

        cell.textLabel?.text = mapItem.name
        if let addressDictionary = mapItem.placemark.addressDictionary,
               addressLines = addressDictionary["FormattedAddressLines"] as? [String]
        {
            cell.detailTextLabel?.text = addressLines.joinWithSeparator(", ")
        }
        
        return cell
    }
    
}
