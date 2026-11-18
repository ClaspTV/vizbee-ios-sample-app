//
//  CastSessionTests.swift
//  VizbeeDemoUITests
//
//  Copyright © Vizbee Inc. All rights reserved.
//

import XCTest

/// Drives cast sessions for the performance runner (performance/run.sh, steps cast and leaks):
/// connects to the TV named in PERF_TV, plays a video on it, disconnects, and prints a timestamped
/// mark at each step. PERF_CYCLES repeats the session; PERF_BEFORE_SECONDS, PERF_CASTING_SECONDS
/// and PERF_AFTER_SECONDS set how long the app stays before connecting, while casting, and after
/// disconnecting.
final class CastSessionTests: XCTestCase {

    private let app = XCUIApplication()

    func testCastSession() throws {
        continueAfterFailure = false
        let tv = setting("PERF_TV", "")
        let cycles = Int(setting("PERF_CYCLES", "1")) ?? 1
        app.launch()
        mark("launched", 0)
        hold("PERF_BEFORE_SECONDS", 60)
        for cycle in 1...cycles {
            mark("connect", cycle)
            connect(to: tv)
            mark("connected", cycle)
            app.staticTexts["Big Buck Bunny"].firstMatch.tap()
            play()
            mark("playing", cycle)
            hold("PERF_CASTING_SECONDS", 180)
            mark("disconnect", cycle)
            disconnect()
            mark("disconnected", cycle)
            app.navigationBars.buttons.element(boundBy: 0).tap()
            hold("PERF_AFTER_SECONDS", 180)
            mark("end", cycle)
        }
    }

    override func record(_ issue: XCTIssue) {
        print(app.debugDescription)
        super.record(issue)
    }

    private func setting(_ name: String, _ defaultValue: String) -> String {
        ProcessInfo.processInfo.environment[name] ?? defaultValue
    }

    private func hold(_ name: String, _ defaultSeconds: TimeInterval) {
        Thread.sleep(forTimeInterval: TimeInterval(setting(name, "")) ?? defaultSeconds)
    }

    private func mark(_ name: String, _ cycle: Int) {
        print(String(format: "PERF_MARK %@ %d %.3f", name, cycle, Date().timeIntervalSince1970))
    }

    private func waitUntil(_ element: XCUIElement, _ format: String, timeout: TimeInterval, _ message: String) {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: format), object: element)
        XCTAssertEqual(XCTWaiter().wait(for: [expectation], timeout: timeout), .completed, message)
    }

    private func tapButton(labelled label: String, timeout: TimeInterval = 10) {
        let button = app.buttons.matching(NSPredicate(format: "label ==[c] %@", label)).firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: timeout), "no button labelled '\(label)'")
        button.tap()
    }

    private func tapDevice(named name: String) {
        let contains = NSPredicate(format: "label CONTAINS[c] %@", name)
        let button = app.buttons.matching(contains).firstMatch
        let cell = app.cells.containing(contains).firstMatch
        let deadline = Date().addingTimeInterval(30)
        while !button.exists && !cell.exists && Date() < deadline {
            Thread.sleep(forTimeInterval: 1)
        }
        let row = button.exists ? button : cell
        XCTAssertTrue(row.exists, "no device named '\(name)' in the device list")
        waitUntil(row, "isHittable == true", timeout: 20, "the device row for '\(name)' cannot be tapped")
        Thread.sleep(forTimeInterval: 1)
        row.tap()
    }

    // MARK: - Without SDK: the same screens, without casting

    private func connect(to tv: String) {
    }

    private func play() {
    }

    private func disconnect() {
    }
}
