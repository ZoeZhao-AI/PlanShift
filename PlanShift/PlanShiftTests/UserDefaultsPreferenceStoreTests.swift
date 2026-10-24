//
//  UserDefaultsPreferenceStoreTests.swift
//  PlanShiftTests
//
//  Created by Chang Chia ming on 2026/10/21.
//

import Foundation
import XCTest
@testable import PlanShift

final class UserDefaultsPreferenceStoreTests: XCTestCase {
    @MainActor
    func testEmptyStoreReturnsDefaultPreferences() throws {
        try withDefaults { defaults in
            let store = UserDefaultsPreferenceStore(defaults: defaults)
            let filters = store.load()

            XCTAssertEqual(filters.budget, .under30)
            XCTAssertEqual(filters.setting, .any)
            XCTAssertEqual(filters.maxDistance, .threeKm)
            XCTAssertEqual(
                filters.duration,
                PreferenceFilters().duration
            )
        }
    }

    @MainActor
    func testSaveThenLoadReturnsSelectedPreferences() throws {
        try withDefaults { defaults in
            let store = UserDefaultsPreferenceStore(defaults: defaults)
            var filters = PreferenceFilters()
            filters.budget = .free
            filters.setting = .indoor
            filters.maxDistance = .oneKm

            store.save(filters)

            let loaded = store.load()
            XCTAssertEqual(loaded.budget, .free)
            XCTAssertEqual(loaded.setting, .indoor)
            XCTAssertEqual(loaded.maxDistance, .oneKm)
        }
    }

    @MainActor
    func testNewStoreReadsPreviouslySavedPreferences() throws {
        try withDefaults { defaults in
            let first = UserDefaultsPreferenceStore(defaults: defaults)
            var filters = PreferenceFilters()
            filters.budget = .any
            filters.setting = .outdoor
            filters.maxDistance = .fiveKmPlus

            first.save(filters)

            let second = UserDefaultsPreferenceStore(defaults: defaults)
            let loaded = second.load()

            XCTAssertEqual(loaded.budget, .any)
            XCTAssertEqual(loaded.setting, .outdoor)
            XCTAssertEqual(loaded.maxDistance, .fiveKmPlus)
        }
    }

    @MainActor
    func testInvalidStoredValuesFallBackToDefaults() throws {
        try withDefaults { defaults in
            defaults.set("invalid", forKey: "preferences.budget")
            defaults.set("invalid", forKey: "preferences.setting")
            defaults.set("invalid", forKey: "preferences.maxDistance")

            let store = UserDefaultsPreferenceStore(defaults: defaults)
            let filters = store.load()

            XCTAssertEqual(filters.budget, .under30)
            XCTAssertEqual(filters.setting, .any)
            XCTAssertEqual(filters.maxDistance, .threeKm)
        }
    }

    @MainActor
    private func withDefaults(
        _ body: (UserDefaults) throws -> Void
    ) throws {
        let suiteName = "UserDefaultsPreferenceStoreTests.\(UUID())"
        let defaults = try XCTUnwrap(
            UserDefaults(suiteName: suiteName)
        )
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        try body(defaults)
    }
}
