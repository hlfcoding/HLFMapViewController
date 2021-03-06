//
//  HLFMapViewController_Example_UITests.swift
//  HLFMapViewController_Example_UITests
//
//  Created by Peng Wang on 1/4/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import XCTest

class HLFMapViewController_Example_UITests: XCTestCase {

    let existsPredicate = NSPredicate(format: "exists == 1")

    override func setUp() {
        super.setUp()

        continueAfterFailure = false
        XCUIApplication().launch()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testBasicUserFlow() {
        let app = XCUIApplication()
        let presentButton = app.buttons["Show Map"]
        let userLocation = app.otherElements["My Location"]
        let searchField = app.navigationBars["Select Nearby Location"].searchFields["Search for place or address"]
        let searchResult = app.tables["Search results"].staticTexts["Apple Inc., 1 Infinite Loop, Cupertino, CA 95014-2083, United States"]
        let selectButton = app.buttons["Select address in callout view"]
        let deselectButton = app.buttons["Deselect address in callout view"]
        let calloutTitle = app.staticTexts["Apple Inc., 1 Infinite Loop, Cupertino, CA 95014-2083, United States"]

        presentButton.tap()

        expectation(for: existsPredicate, evaluatedWith: userLocation, handler: nil)
        waitForExpectations(timeout: 10, handler: nil)

        searchField.tap()
        searchField.typeText("Apple Inc., Cupertino")
        searchResult.tap()

        expectation(for: existsPredicate, evaluatedWith: calloutTitle, handler: nil)
        waitForExpectations(timeout: 2, handler: nil)

        selectButton.tap()

        expectation(for: existsPredicate, evaluatedWith: presentButton, handler: nil)
        waitForExpectations(timeout: 2, handler: nil)

        presentButton.tap()

        expectation(for: existsPredicate, evaluatedWith: calloutTitle, handler: nil)
        expectation(for: existsPredicate, evaluatedWith: deselectButton, handler: nil)
        waitForExpectations(timeout: 10, handler: nil)
    }

}
