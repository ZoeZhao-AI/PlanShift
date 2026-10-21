//
//  SettingsPreferencesViewModelTests.swift
//  PlanShiftTests
//
//  Created by Chang Chia ming on 2026/10/21.
//

import Foundation
import XCTest
@testable import PlanShift

final class SettingsPreferencesViewModelTests: XCTestCase {
    @MainActor
    func testInitialStateLoadsSavedPreferences() throws {
        try withStore { store in
            var saved = PreferenceFilters()
            saved.budget = .free
            saved.setting = .outdoor
            saved.maxDistance = .fiveKmPlus
            store.save(saved)

            let model = SettingsPreferencesViewModel(store: store)

            XCTAssertEqual(model.filters, saved)
        }
    }

    @MainActor
    func testChangingBudgetSavesAndPreservesOtherPreferences() throws {
        try withStore { store in
            let model = SettingsPreferencesViewModel(store: store)
            var expected = model.filters
            expected.budget = .free

            model.setBudget(.free)

            XCTAssertEqual(model.filters, expected)
            XCTAssertEqual(store.load(), expected)
        }
    }

    @MainActor
    func testChangingSettingSavesAndPreservesOtherPreferences() throws {
        try withStore { store in
            let model = SettingsPreferencesViewModel(store: store)
            var expected = model.filters
            expected.setting = .indoor

            model.setSetting(.indoor)

            XCTAssertEqual(model.filters, expected)
            XCTAssertEqual(store.load(), expected)
        }
    }

    @MainActor
    func testChangingDistanceSavesAndPreservesOtherPreferences() throws {
        try withStore { store in
            let model = SettingsPreferencesViewModel(store: store)
            var expected = model.filters
            expected.maxDistance = .oneKm

            model.setMaxDistance(.oneKm)

            XCTAssertEqual(model.filters, expected)
            XCTAssertEqual(store.load(), expected)
        }
    }
    
    @MainActor
    func testInitialStateLoadsSavedAppearance() throws {
        try withAppearanceStore { appearanceStore in
            try withStore { preferenceStore in
                appearanceStore.save(.dark)

                let model = SettingsPreferencesViewModel(
                    store: preferenceStore,
                    appearanceStore: appearanceStore
                )

                XCTAssertEqual(model.appearance, .dark)
            }
        }
    }

    @MainActor
    func testChangingAppearanceSavesAndPreservesPreferences() throws {
        try withAppearanceStore { appearanceStore in
            try withStore { preferenceStore in
                let model = SettingsPreferencesViewModel(
                    store: preferenceStore,
                    appearanceStore: appearanceStore
                )
                let originalFilters = model.filters

                model.setAppearance(.light)

                XCTAssertEqual(model.appearance, .light)
                XCTAssertEqual(appearanceStore.load(), .light)
                XCTAssertEqual(model.filters, originalFilters)
                XCTAssertEqual(preferenceStore.load(), originalFilters)
            }
        }
    }

    @MainActor
    private func withAppearanceStore(
        _ body: (UserDefaultsAppearanceStore) throws -> Void
    ) throws {
        let suiteName = "SettingsAppearanceTests.\(UUID())"
        let defaults = try XCTUnwrap(
            UserDefaults(suiteName: suiteName)
        )
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        try body(UserDefaultsAppearanceStore(defaults: defaults))
    }

    @MainActor
    private func withStore(
        _ body: (UserDefaultsPreferenceStore) throws -> Void
    ) throws {
        let suiteName = "SettingsPreferencesViewModelTests.\(UUID())"
        let defaults = try XCTUnwrap(
            UserDefaults(suiteName: suiteName)
        )
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let store = UserDefaultsPreferenceStore(defaults: defaults)
        try body(store)
    }
}
