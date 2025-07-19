//
//  scripterUITests.swift
//  scripterUITests
//
//  Created by Chandra Dasari on 7/2/25.
//

import XCTest

final class scripterUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }

    // @MainActor
    // func testCreateNewScript() throws {
    //     let app = XCUIApplication()
    //     app.launch()
    //     let newScriptButton = app.buttons["New Script"]
    //     XCTAssertTrue(newScriptButton.waitForExistence(timeout: 2))
    //     newScriptButton.tap()
    //     let scriptNameField = app.textFields["Script Name"]
    //     XCTAssertTrue(scriptNameField.waitForExistence(timeout: 2))
    //     scriptNameField.tap()
    //     scriptNameField.typeText("Test Script")
    //     let scriptContentEditor = app.textViews.element(boundBy: 0)
    //     XCTAssertTrue(scriptContentEditor.waitForExistence(timeout: 2))
    //     scriptContentEditor.tap()
    //     scriptContentEditor.typeText("echo 'Hello from test!'")
    //     let saveButton = app.buttons["Save"]
    //     XCTAssertTrue(saveButton.isEnabled)
    //     saveButton.tap()
    //     let scriptCell = app.staticTexts["Test Script"]
    //     XCTAssertTrue(scriptCell.waitForExistence(timeout: 2))
    // }

    // @MainActor
    // func testEditScript() throws {
    //     let app = XCUIApplication()
    //     app.launch()
    //     let scriptCell = app.staticTexts["Test Script"]
    //     XCTAssertTrue(scriptCell.waitForExistence(timeout: 2))
    //     scriptCell.click()
    //     scriptCell.press(forDuration: 1.0)
    //     let editButton = app.menuItems["Edit"]
    //     XCTAssertTrue(editButton.waitForExistence(timeout: 2))
    //     editButton.tap()
    //     let scriptNameField = app.textFields["Script Name"]
    //     XCTAssertTrue(scriptNameField.waitForExistence(timeout: 2))
    //     scriptNameField.tap()
    //     scriptNameField.typeText(" Edited")
    //     let saveButton = app.buttons["Save"]
    //     XCTAssertTrue(saveButton.isEnabled)
    //     saveButton.tap()
    //     let updatedScriptCell = app.staticTexts["Test Script Edited"]
    //     XCTAssertTrue(updatedScriptCell.waitForExistence(timeout: 2))
    // }

    // @MainActor
    // func testDeleteScript() throws {
    //     let app = XCUIApplication()
    //     app.launch()
    //     let scriptCell = app.staticTexts["Test Script Edited"]
    //     XCTAssertTrue(scriptCell.waitForExistence(timeout: 2))
    //     scriptCell.click()
    //     scriptCell.press(forDuration: 1.0)
    //     let deleteButton = app.menuItems["Delete"]
    //     XCTAssertTrue(deleteButton.waitForExistence(timeout: 2))
    //     deleteButton.tap()
    //     XCTAssertFalse(scriptCell.waitForExistence(timeout: 2))
    // }

    // @MainActor
    // func testRunScript() throws {
    //     let app = XCUIApplication()
    //     app.launch()
    //     let scriptCell = app.staticTexts["Test Script"]
    //     XCTAssertTrue(scriptCell.waitForExistence(timeout: 2))
    //     scriptCell.click()
    //     scriptCell.press(forDuration: 1.0)
    //     let runButton = app.menuItems["Run"]
    //     XCTAssertTrue(runButton.waitForExistence(timeout: 2))
    //     runButton.tap()
    // }
}
