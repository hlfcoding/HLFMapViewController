//
//  SearchResultsViewController.swift
//  MapViewController
//
//  Created by Peng Wang on 8/6/15.
//  Copyright © 2015 pengxwang. All rights reserved.
//

import Contacts
import MapKit
import UIKit

class SearchResultsViewController: UITableViewController {

    let cellReuseIdentifier = "searchResult"

    var mapItems: [MKMapItem] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.registerClass(SearchResultsViewCell.self, forCellReuseIdentifier: self.cellReuseIdentifier)
        self.tableView.registerNib(UINib(nibName: "SearchResultsViewCell", bundle: nil), forCellReuseIdentifier: self.cellReuseIdentifier)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

        self.mapItems = []
    }

    // MARK: UITableViewDataSource

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.mapItems.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(self.cellReuseIdentifier, forIndexPath: indexPath)
        let mapItem = self.mapItems[indexPath.row]

        cell.textLabel?.text = mapItem.name
        if let addressDictionary = mapItem.placemark.addressDictionary,
               addressLines = addressDictionary["FormattedAddressLines"] as? [String]
        {
            cell.detailTextLabel?.text = ", ".join(addressLines)
        }

        return cell
    }

}
