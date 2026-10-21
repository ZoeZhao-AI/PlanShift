//
//  UserDefaultsAppearanceStore.swift
//  PlanShift
//
//  Created by Chang Chia ming on 2026/10/21.
//

import Foundation

@MainActor
struct UserDefaultsAppearanceStore {
    static let storageKey = "preferences.appearance"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> AppearanceOption {
        defaults.string(forKey: Self.storageKey)
            .flatMap { AppearanceOption(rawValue: $0) } ?? .automatic
    }

    func save(_ appearance: AppearanceOption) {
        defaults.set(
            appearance.rawValue,
            forKey: Self.storageKey
        )
    }
}
