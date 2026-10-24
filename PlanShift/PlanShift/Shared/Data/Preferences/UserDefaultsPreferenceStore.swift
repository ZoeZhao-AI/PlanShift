//
//  UserDefaultsPreferenceStore.swift
//  PlanShift
//
//  Created by Chang Chia ming on 2026/10/21.
//

import Foundation

@MainActor
struct UserDefaultsPreferenceStore {
    private let defaults: UserDefaults

    private enum Keys {
        static let budget = "preferences.budget"
        static let setting = "preferences.setting"
        static let maxDistance = "preferences.maxDistance"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> PreferenceFilters {
        var filters = PreferenceFilters()

        filters.budget = defaults.string(forKey: Keys.budget)
            .flatMap { BudgetOption(rawValue: $0) } ?? .under30

        filters.setting = defaults.string(forKey: Keys.setting)
            .flatMap { SettingPreference(rawValue: $0) } ?? .any

        filters.maxDistance = defaults.string(forKey: Keys.maxDistance)
            .flatMap { DistanceOption(rawValue: $0) } ?? .threeKm

        return filters
    }

    func save(_ filters: PreferenceFilters) {
        defaults.set(filters.budget.rawValue, forKey: Keys.budget)
        defaults.set(filters.setting.rawValue, forKey: Keys.setting)
        defaults.set(filters.maxDistance.rawValue, forKey: Keys.maxDistance)
    }
}
