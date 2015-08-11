//
//  MapViewControllerUITests.swift
//  MapViewControllerUITests
//
//  Created by Peng Wang on 8/3/15.
//  Copyright © 2015 pengxwang. All rights reserved.
//

import XCTest

class MapViewControllerUITests: XCTestCase {

    let existsPredicate = NSPredicate(format: "exists == 1")

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
        let presentButton = app.buttons["Show Map"]

        presentButton.tap()

        let locationAnnotation = app.otherElements["Current Location"]

        self.expectationForPredicate(self.existsPredicate, evaluatedWithObject: locationAnnotation, handler: nil)
        self.waitForExpectationsWithTimeout(5.0, handler: nil)

        let searchField = app.navigationBars["Select Nearby Location"].searchFields["Search for place or address"]
        searchField.tap()
        searchField.typeText("Apple Inc., Cupertino")
        app.tables["Search results"].staticTexts["Apple Inc., 1 Infinite Loop, Cupertino, CA 95014-2083, United States"].tap()

        app.buttons["Select address in callout view"].tap()

        self.expectationForPredicate(self.existsPredicate, evaluatedWithObject: presentButton, handler: nil)
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }
    
}
