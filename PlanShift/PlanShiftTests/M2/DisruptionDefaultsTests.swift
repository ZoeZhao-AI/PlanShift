//
//  DisruptionDefaultsTests.swift
//  PlanShiftTests
//
//  Created by Van Dao Le on 15/10/2026.
//

// Module: M2 tests – ApplyDisruptionDefaults.

import XCTest
@testable import PlanShift

final class DisruptionDefaultsTests: XCTestCase {
    private let defaults = ApplyDisruptionDefaults()

    func testEachDisruptionSetsItsInitialFilter() {
        XCTAssertEqual(defaults.filters(for: .rainyWeather).setting, .indoor)
        XCTAssertEqual(defaults.filters(for: .transportDelay).maxDistance, .oneKm)
        XCTAssertEqual(defaults.filters(for: .runningOutOfTime).duration, .underOneHour)
        XCTAssertEqual(defaults.filters(for: .attractionClosed), PreferenceFilters(), "closed attraction is handled by ranking, not a hard filter")
    }

    func testDefaultsKeepTheUsersBaseChoices() {
        let base = PreferenceFilters(budget: .free, maxDistance: .fiveKmPlus, duration: .halfDay, setting: .outdoor)
        let rainy = defaults.filters(for: .rainyWeather, base: base)
        XCTAssertEqual(rainy.budget, .free)
        XCTAssertEqual(rainy.maxDistance, .fiveKmPlus)
        XCTAssertEqual(rainy.setting, .indoor)
    }
}
