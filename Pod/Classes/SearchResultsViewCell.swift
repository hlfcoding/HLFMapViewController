//
//  SearchResultsViewCell.swift
//  MapViewController
//
//  Created by Peng Wang on 8/7/2015.
//  Copyright © 2015 Peng Wang. All rights reserved.
//

import UIKit

@objc(HLFSearchResultsViewCell)
open class SearchResultsViewCell: UITableViewCell {

    static let reuseIdentifier = "SearchResult"

    @IBOutlet open weak var customTextLabel: UILabel!
    @IBOutlet open weak var customDetailTextLabel: UILabel!

}
