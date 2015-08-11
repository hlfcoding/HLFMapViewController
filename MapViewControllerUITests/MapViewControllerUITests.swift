//
//  MapViewControllerUITests.swift
//  MapViewControllerUITests
//
//  Created by Peng Wang on 8/3/15.
//  Copyright © 2015 pengxwang. All rights reserved.
//

import XCTest

class MapViewControllerUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()

        self.continueAfterFailure = false
        XCUIApplication().launch()
    }

    override func tearDown() {
        super.tearDown()
    }
    
    func testBasicUserFlow() {
        let app = XCUIApplication()

        app.buttons["Show Map"].tap()

        let searchField = app.navigationBars["Select Nearby Location"].searchFields["Search for place or address"]
        searchField.tap()
        searchField.typeText("Apple Inc., Cupertino")
        app.tables["Search results"].staticTexts["Apple Inc., 1 Infinite Loop, Cupertino, CA 95014-2083, United States"].tap()

        app.buttons["Select address in callout view"].tap()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
}
