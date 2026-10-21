//
//  UserDefaultsAppearanceStoreTests.swift
//  PlanShiftTests
//
//  Created by Chang Chia ming on 2026/10/21.
//

import Foundation
import XCTest
@testable import PlanShift

final class UserDefaultsAppearanceStoreTests: XCTestCase {
    @MainActor
    func testEmptyStoreReturnsAutomatic() throws {
        try withDefaults { defaults in
            let store = UserDefaultsAppearanceStore(defaults: defaults)

            XCTAssertEqual(store.load(), .automatic)
        }
    }

    @MainActor
    func testEveryAppearanceCanBeSavedAndLoaded() throws {
        try withDefaults { defaults in
            let store = UserDefaultsAppearanceStore(defaults: defaults)

            for appearance in AppearanceOption.allCases {
                store.save(appearance)

                XCTAssertEqual(store.load(), appearance)
            }
        }
    }

    @MainActor
    func testNewStoreReadsSavedAppearance() throws {
        try withDefaults { defaults in
            let first = UserDefaultsAppearanceStore(defaults: defaults)
            first.save(.dark)

            let second = UserDefaultsAppearanceStore(defaults: defaults)

            XCTAssertEqual(second.load(), .dark)
        }
    }

    @MainActor
    func testInvalidValueFallsBackToAutomatic() throws {
        try withDefaults { defaults in
            defaults.set(
                "invalid",
                forKey: UserDefaultsAppearanceStore.storageKey
            )

            let store = UserDefaultsAppearanceStore(defaults: defaults)

            XCTAssertEqual(store.load(), .automatic)
        }
    }

    @MainActor
    private func withDefaults(
        _ body: (UserDefaults) throws -> Void
    ) throws {
        let suiteName = "UserDefaultsAppearanceStoreTests.\(UUID())"
        let defaults = try XCTUnwrap(
            UserDefaults(suiteName: suiteName)
        )
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        try body(defaults)
    }
}
