//
//  SearchResultsViewController.swift
//  MapViewController
//
//  Created by Peng Wang on 8/6/2015.
//  Copyright © 2015 Peng Wang. All rights reserved.
//

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

    /**
     Blur style defaults to `light`. This method allows customizing that.
     */
    @objc optional func resultsViewControllerBlurEffect(_ resultsViewController: SearchResultsViewController) -> UIBlurEffect

}

@objc(HLFSearchResultsViewController)
open class SearchResultsViewController: UITableViewController {

    /** Not required, but this view controller is pretty useless without a delegate. */
    open weak var delegate: SearchResultsViewControllerDelegate?

    @IBOutlet open weak var blurView: UIVisualEffectView!
    @IBOutlet open weak var vibrancyView: UIVisualEffectView!

    open var mapItems: [MKMapItem] = [] {
        didSet {
            if debug { print("Reloading with \(mapItems.count) items") }
            tableView.reloadData()
        }
    }

    open var debug = false

    override open func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 10.0, *) {
            automaticallyAdjustsScrollViewInsets = false
        }

        tableView.register(
            SearchResultsViewCell.self, forCellReuseIdentifier: SearchResultsViewCell.reuseIdentifier
        )
        tableView.register(
            UINib(nibName: "SearchResultsViewCell", bundle: MapViewController.bundle),
            forCellReuseIdentifier: SearchResultsViewCell.reuseIdentifier
        )

        if let effect = delegate?.resultsViewControllerBlurEffect?(self) {
            blurView.effect = effect
            vibrancyView.effect = UIVibrancyEffect(blurEffect: effect)
        }
        tableView.backgroundView = blurView
        tableView.separatorEffect = vibrancyView.effect
    }

    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if #available(iOS 10.0, *) {
            let correctOffset = presentingViewController!.topLayoutGuide.length
            tableView.contentInset.top = correctOffset
            tableView.scrollIndicatorInsets.top = correctOffset
        }
    }

    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

        mapItems = []
    }

    // MARK: UITableViewDataSource

    override open func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override open func tableView(_ tableView: UITableView,
                                 numberOfRowsInSection section: Int) -> Int {
        return mapItems.count
    }

    override open func tableView(_ tableView: UITableView,
                                 cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let someCell = tableView.dequeueReusableCell(
            withIdentifier: SearchResultsViewCell.reuseIdentifier, for: indexPath
        )
        guard let cell = someCell as? SearchResultsViewCell else { return someCell }

        let mapItem = mapItems[indexPath.row]
        cell.customTextLabel.text = mapItem.name
        if let addressDictionary = mapItem.placemark.addressDictionary,
            let addressLines = addressDictionary["FormattedAddressLines"] as? [String] {
            cell.customDetailTextLabel.text = addressLines.joined(separator: ", ")
        }

        delegate?.resultsViewController?(
            self, didConfigureResultViewCell: cell, withMapItem: mapItem
        )

        return cell
    }

}
