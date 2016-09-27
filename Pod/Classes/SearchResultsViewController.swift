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

@objc(HLFSearchResultsViewControllerDelegate)
public protocol SearchResultsViewControllerDelegate: NSObjectProtocol {

    /**
     When the cell is dequeued and initially given content, this method
     will be called to allow additional customization of the cell, for
     example, its `layoutMargins` and label colors and font sizes.
     */
    @objc optional func resultsViewController(_ resultsViewController: SearchResultsViewController,
                                              didConfigureResultViewCell cell: SearchResultsViewCell,
                                              withMapItem mapItem: MKMapItem)

}


@objc(HLFSearchResultsViewController)
open class SearchResultsViewController: UITableViewController {

    /** Not required, but this view controller is pretty useless without a delegate. */
    open weak var delegate: SearchResultsViewControllerDelegate?

    open var mapItems: [MKMapItem] = [] {
        didSet {
            if self.debug { print("Reloading with \(self.mapItems.count) items") }
            self.tableView.reloadData()
        }
    }

    open var debug = false

    override open func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.register(
            SearchResultsViewCell.self, forCellReuseIdentifier: SearchResultsViewCell.reuseIdentifier
        )
        self.tableView.register(
            UINib(nibName: "SearchResultsViewCell", bundle: MapViewController.bundle),
            forCellReuseIdentifier: SearchResultsViewCell.reuseIdentifier
        )
    }

    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

        self.mapItems = []
    }

    // MARK: UITableViewDataSource

    override open func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override open func tableView(_ tableView: UITableView,
                                 numberOfRowsInSection section: Int) -> Int {
        return self.mapItems.count
    }

    override open func tableView(_ tableView: UITableView,
                                 cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let someCell = tableView.dequeueReusableCell(
            withIdentifier: SearchResultsViewCell.reuseIdentifier, for: indexPath
        )
        guard let cell = someCell as? SearchResultsViewCell else { return someCell }

        let mapItem = self.mapItems[indexPath.row]
        cell.customTextLabel.text = mapItem.name
        if let addressDictionary = mapItem.placemark.addressDictionary,
            let addressLines = addressDictionary["FormattedAddressLines"] as? [String] {
            cell.customDetailTextLabel.text = addressLines.joined(separator: ", ")
        }

        self.delegate?.resultsViewController?(
            self, didConfigureResultViewCell: cell, withMapItem: mapItem
        )

        return cell
    }

}
