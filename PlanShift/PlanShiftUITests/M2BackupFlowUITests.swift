// Module: M2 UI test – bookmark an alternative in the disruption flow and find it in the Backups tab.

import XCTest

final class M2BackupFlowUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testBookmarkAppearsInBackupsTab() throws {
        let app = XCUIApplication()
        app.launch()
        let savedPlace = openResultsAndBookmarkFirst(app)

        // Toast action → Backups tab.
        tap(app.buttons["View"], in: app, "View toast action")
        snapshot(app, "4-backups-tab")
        XCTAssertTrue(backupRow(savedPlace, in: app).waitForExistence(timeout: 5), "Backups tab does not show \(savedPlace)")
    }

    /// Second tap on the same bookmark → duplicate warning, still one row; tapping the row opens M4-02.
    @MainActor
    func testDuplicateBookmarkAndUseBackup() throws {
        let app = XCUIApplication()
        app.launch()
        let savedPlace = openResultsAndBookmarkFirst(app)

        // Same bookmark again.
        app.buttons.matching(NSPredicate(format: "label == %@", "Backup \(savedPlace)")).firstMatch.tap()
        XCTAssertTrue(
            app.staticTexts["This activity is already in your backups"].waitForExistence(timeout: 5),
            "No duplicate warning on the second bookmark"
        )
        snapshot(app, "5-duplicate-warning")

        // Backups tab, exactly one row. (Relaunch persistence is not asserted: `PreviewSamples.trip` gets a new
        // id on every launch until M1 provides a stored trip, so backups saved earlier belong to another trip.)
        tap(app.buttons["View"], in: app, "View toast action")
        XCTAssertTrue(backupRow(savedPlace, in: app).waitForExistence(timeout: 8), "Backup row missing")
        XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label == %@", savedPlace)).count, 1, "Duplicate rows")
        snapshot(app, "6-backups-one-row")

        // M4-02.
        backupRow(savedPlace, in: app).tap()
        XCTAssertTrue(app.staticTexts["Replace which activity?"].waitForExistence(timeout: 5), "Use backup did not open")
        snapshot(app, "7-use-backup")
    }

    /// M4-02 → Continue → M3-01 → Confirm: the activity is replaced, M3-02 shows, and the original lands in Backups.
    @MainActor
    func testContinueToReplaceConfirmation() throws {
        let app = XCUIApplication()
        app.launch()
        let savedPlace = openResultsAndBookmarkFirst(app)
        tap(app.buttons["View"], in: app, "View toast action")
        tap(backupRow(savedPlace, in: app), in: app, "backup row")

        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
        XCTAssertFalse(continueButton.isEnabled, "Continue must be disabled until an activity is chosen")

        tap(app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Bondi to Coogee Coastal Walk'")).firstMatch, in: app, "activity row")
        XCTAssertTrue(continueButton.isEnabled, "Continue should enable after choosing an activity")
        snapshot(app, "8-activity-selected")
        continueButton.tap()

        // M3-01.
        XCTAssertTrue(app.staticTexts["Replace activity?"].waitForExistence(timeout: 5), "M3-01 did not open")
        snapshot(app, "9-replace-confirmation")
        tap(app.buttons["Confirm replace"], in: app, "Confirm replace")

        // M3-02 on the Itinerary tab.
        XCTAssertTrue(app.staticTexts["Plan updated"].waitForExistence(timeout: 8), "Updated itinerary banner missing")
        snapshot(app, "10-plan-updated")

        // The replaced original is now a backup.
        tap(app.tabBars.buttons["Backups"], in: app, "Backups tab")
        XCTAssertTrue(backupRow("Bondi to Coogee Coastal Walk", in: app).waitForExistence(timeout: 8), "Original plan not in Backups")
        snapshot(app, "11-backups-with-original")
    }

    // MARK: - Real location permission
    //
    // These use the real iOS permission dialog and `CoreLocationService`, so they need the permission reset and a
    // simulated position first. They are skipped unless REAL_LOCATION_TEST=1 is passed to the test runner:
    //
    //   xcrun simctl privacy booted reset location com.utsstudent.zhaoziying.PlanShift
    //   xcrun simctl location booted set -33.8688,151.2093
    //   TEST_RUNNER_REAL_LOCATION_TEST=1 xcodebuild test -only-testing:PlanShiftUITests/M2BackupFlowUITests/<name> ...

    /// "Allow While Using App" → ranking uses the device position (Sydney CBD), so the footnote says so.
    @MainActor
    func testRealLocationAllowWhileUsing() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["REAL_LOCATION_TEST"] == "1", "Needs the real-permission setup above")
        answerSystemLocationAlert(with: ["Allow While Using App", "Allow Once"])
        let app = XCUIApplication()
        app.launch()
        startRainyFlowWithWideDistance(app)

        tap(app.buttons["Allow location"], in: app, "Allow location")
        let bookmark = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Backup '")).firstMatch
        XCTAssertTrue(waitForSystemAlertThenExist(bookmark, in: app), "No results after allowing location")
        snapshot(app, "40-real-location-allowed")
        let footnote = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'from your location'")).firstMatch
        if !footnote.exists { app.swipeUp() }
        XCTAssertTrue(footnote.waitForExistence(timeout: 5), "Distances were not measured from the device location")
    }

    /// "Don't Allow" → graceful banner, ranking falls back to the planned activity.
    @MainActor
    func testRealLocationDontAllow() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["REAL_LOCATION_TEST"] == "1", "Needs the real-permission setup above")
        answerSystemLocationAlert(with: ["Don\u{2019}t Allow", "Don't Allow"])
        let app = XCUIApplication()
        app.launch()
        startRainyFlowWithWideDistance(app)

        tap(app.buttons["Allow location"], in: app, "Allow location")
        let bookmark = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Backup '")).firstMatch
        XCTAssertTrue(waitForSystemAlertThenExist(bookmark, in: app), "Ranking must still work after Don't Allow")
        snapshot(app, "41-real-location-denied")
        XCTAssertTrue(
            app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Location is off'")).firstMatch.waitForExistence(timeout: 5),
            "Location-off banner missing"
        )
    }

    @MainActor
    private func startRainyFlowWithWideDistance(_ app: XCUIApplication) {
        tap(app.buttons["Activity Detail"], in: app, "Activity Detail button")
        tap(app.buttons["Plan Disrupted"], in: app, "Plan Disrupted button")
        tap(app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Rainy weather'")).firstMatch, in: app, "Rainy weather")
        tap(app.buttons["5 km+"], in: app, "5 km+")
        app.buttons["Show alternatives"].tap()
    }

    @MainActor
    private func answerSystemLocationAlert(with labels: [String]) {
        addUIInterruptionMonitor(withDescription: "Location permission") { alert in
            for label in labels where alert.buttons[label].exists {
                alert.buttons[label].tap()
                return true
            }
            return false
        }
    }

    /// The interruption monitor only fires when the test interacts with the app, so nudge it while waiting.
    @MainActor
    private func waitForSystemAlertThenExist(_ element: XCUIElement, in app: XCUIApplication) -> Bool {
        for _ in 0..<6 {
            if element.waitForExistence(timeout: 3) { return true }
            app.tap()
        }
        return element.exists
    }

    // MARK: - Flow

    /// Itinerary → disruption flow → results (widening the 3 km filter if needed) → bookmarks result #1.
    @MainActor
    private func openResultsAndBookmarkFirst(_ app: XCUIApplication) -> String {
        tap(app.buttons["Activity Detail"], in: app, "Activity Detail button")
        tap(app.buttons["Plan Disrupted"], in: app, "Plan Disrupted button")
        tap(app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Rainy weather'")).firstMatch, in: app, "Rainy weather")
        tap(app.buttons["Show alternatives"], in: app, "Show alternatives")

        // M2-02 may ask for location first; decline so ranking uses the planned activity.
        let notNow = app.buttons["Not now"]
        if notNow.waitForExistence(timeout: 2) { notNow.tap() }

        let adjust = app.buttons["Adjust filters"]
        if adjust.waitForExistence(timeout: 6), !app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Backup '")).firstMatch.exists {
            // M2-04: the default 3 km filter finds nothing near Bondi, so widen it (a valid empty state).
            snapshot(app, "2b-no-results")
            adjust.tap()
            tap(app.buttons["5 km+"], in: app, "5 km+ segment")
            tap(app.buttons["Show alternatives"], in: app, "Show alternatives (again)")
            if notNow.waitForExistence(timeout: 2) { notNow.tap() }
        }

        let bookmark = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Backup '")).firstMatch
        XCTAssertTrue(bookmark.waitForExistence(timeout: 10), "No alternatives with a bookmark button appeared")
        snapshot(app, "2c-results")
        let savedPlace = String(bookmark.label.dropFirst("Backup ".count))
        bookmark.tap()
        XCTAssertTrue(
            app.staticTexts["Saved to backups"].waitForExistence(timeout: 5)
                || app.staticTexts["This activity is already in your backups"].exists,
            "No toast after bookmarking"
        )
        snapshot(app, "3-after-bookmark")
        return savedPlace
    }

    private func backupRow(_ name: String, in app: XCUIApplication) -> XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label == %@", name)).firstMatch
    }

    // MARK: - Helpers

    @MainActor
    private func tap(_ element: XCUIElement, in app: XCUIApplication, _ name: String) {
        if !element.waitForExistence(timeout: 8) { snapshot(app, "missing-\(name)") }
        XCTAssertTrue(element.exists, "\(name) not found")
        element.tap()
    }

    @MainActor
    private func snapshot(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
