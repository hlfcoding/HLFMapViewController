//
//  SearchResultsViewCell.swift
//  MapViewController
//
//  Created by Peng Wang on 8/7/2015.
//  Copyright © 2015 Peng Wang. All rights reserved.
//

import UIKit

@objc(HLFSearchResultsViewCell) final public class SearchResultsViewCell: UITableViewCell {

    static let reuseIdentifier = "SearchResult"

    @IBOutlet public weak var customTextLabel: UILabel!
    @IBOutlet public weak var customDetailTextLabel: UILabel!

}
