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
/// disconnecting. testCastSessionsMemory runs with xcodebuild -enablePerformanceTestsDiagnostics YES:
/// after the first session, Xcode saves a memory graph before and after the remaining sessions.
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
            castSession(cycle, to: tv)
        }
    }

    func testCastSessionsMemory() throws {
        continueAfterFailure = false
        let tv = setting("PERF_TV", "")
        let cycles = Int(setting("PERF_CYCLES", "10")) ?? 10
        app.launch()
        mark("launched", 0)
        hold("PERF_BEFORE_SECONDS", 60)
        castSession(1, to: tv)
        let options = XCTMeasureOptions()
        options.iterationCount = 1
        var iteration = 0
        measure(metrics: [XCTMemoryMetric(application: app)], options: options) {
            iteration += 1
            mark("iteration", iteration)
            guard iteration == options.iterationCount + 2 else {
                return
            }
            for cycle in 2...cycles {
                castSession(cycle, to: tv)
            }
        }
    }

    private func castSession(_ cycle: Int, to tv: String) {
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

    // MARK: - Vizbee

    private var castButton: XCUIElement {
        app.navigationBars.matching(NSPredicate(format: "NOT (identifier BEGINSWITH 'VZB')")).buttons["Cast"].firstMatch
    }

    private func connect(to tv: String) {
        dismissCard()
        if castButton.value as? String == "Connected" {
            castButton.tap()
            tapButton(labelled: "Disconnect")
            waitUntil(castButton, "value != 'Connected'", timeout: 30, "still connected after Disconnect")
            dismissCard()
        }
        castButton.tap()
        tapDevice(named: tv)
        waitUntil(castButton, "value == 'Connected'", timeout: 60, "not connected to '\(tv)'")
        dismissCard()
    }

    private func play() {
        tapButton(labelled: "Play")
        waitUntil(app.buttons["pauseButton"], "exists == true", timeout: 60, "the video did not start playing on the TV")
    }

    private func disconnect() {
        let playerCard = app.navigationBars["VZBSplitPlayerCardView"]
        if !playerCard.exists {
            castButton.tap()
        }
        waitUntil(playerCard, "exists == true", timeout: 10, "the player card did not open")
        tapButton(labelled: "Stop")
        waitUntil(app.buttons["pauseButton"], "exists == false", timeout: 30, "the video did not stop")
        dismissCard()
        castButton.tap()
        tapButton(labelled: "Disconnect")
        waitUntil(castButton, "value != 'Connected'", timeout: 30, "still connected after Disconnect")
        dismissCard()
    }

    private func dismissCard() {
        let splash = app.navigationBars["VZBSplashCardView"]
        if splash.exists {
            waitUntil(splash, "exists == false", timeout: 15, "the splash card did not close")
        }
        let cardBar = app.navigationBars.matching(NSPredicate(format: "identifier BEGINSWITH 'VZB' AND identifier != 'VZBSplashCardView'")).firstMatch
        guard cardBar.waitForExistence(timeout: 2) else {
            return
        }
        let closed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: cardBar)
        guard XCTWaiter().wait(for: [closed], timeout: 5) != .completed else {
            return
        }
        let stop = cardBar.buttons["Stop"]
        let close = cardBar.buttons["VZBCloseButton"]
        guard stop.exists || close.exists else {
            return
        }
        (stop.exists ? stop : close).tap()
        waitUntil(cardBar, "exists == false", timeout: 10, "the Vizbee card did not close")
    }
}
