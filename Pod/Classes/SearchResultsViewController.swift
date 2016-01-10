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

@objc(HLFSearchResultsViewController) final public class SearchResultsViewController: UITableViewController {


    public var mapItems: [MKMapItem] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }

    override public func viewDidLoad() {
        super.viewDidLoad()


        // Update cell layout. (1/2)
        /*
        self.tableView.rowHeight = 50
        */
        self.tableView.separatorInset = UIEdgeInsetsZero
        self.tableView.contentInset = UIEdgeInsetsZero
        self.tableView.registerClass(SearchResultsViewCell.self, forCellReuseIdentifier: SearchResultsViewCell.reuseIdentifier)
        self.tableView.registerNib(UINib(nibName: "SearchResultsViewCell", bundle: MapViewController.bundle), forCellReuseIdentifier: SearchResultsViewCell.reuseIdentifier)
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
        let someCell = tableView.dequeueReusableCellWithIdentifier(SearchResultsViewCell.reuseIdentifier, forIndexPath: indexPath)
        guard let cell = someCell as? SearchResultsViewCell else { return someCell }

        let mapItem = self.mapItems[indexPath.row]
        cell.customTextLabel.text = mapItem.name
        if let addressDictionary = mapItem.placemark.addressDictionary,
               addressLines = addressDictionary["FormattedAddressLines"] as? [String]
        {
            cell.customDetailTextLabel.text = addressLines.joinWithSeparator(", ")
        }

        // Update cell layout. (2/2)
        /*
        let original = cell.contentView.layoutMargins
        cell.contentView.layoutMargins = UIEdgeInsets(
            top: 15.0, left: original.left, bottom: 15.0, right: original.right
        )
        */

        return cell
    }
    
}
