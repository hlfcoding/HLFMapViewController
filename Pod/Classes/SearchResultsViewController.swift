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

@objc(HLFSearchResultsViewControllerDelegate) public protocol SearchResultsViewControllerDelegate: NSObjectProtocol {

    /**
     When the cell is dequeued and initially given content, this method
     will be called to allow additional customization of the cell, for
     example, its `layoutMargins` and label colors and font sizes.
     */
    optional func resultsViewController(resultsViewController: SearchResultsViewController,
                                        didConfigureResultViewCell cell: SearchResultsViewCell,
                                        withMapItem mapItem: MKMapItem)

}


@objc(HLFSearchResultsViewController) final public class SearchResultsViewController: UITableViewController {

    /** Not required, but this view controller is pretty useless without a delegate. */
    public weak var delegate: SearchResultsViewControllerDelegate?

    public var mapItems: [MKMapItem] = [] {
        didSet {
            if self.debug { print("Reloading with \(self.mapItems.count) items") }
            self.tableView.reloadData()
        }
    }

    public var debug = false

    override public func viewDidLoad() {
        super.viewDidLoad()

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

        self.delegate?.resultsViewController?(self, didConfigureResultViewCell: cell, withMapItem: mapItem)

        return cell
    }
    
}
