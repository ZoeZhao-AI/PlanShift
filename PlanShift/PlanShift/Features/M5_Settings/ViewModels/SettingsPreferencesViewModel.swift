//
//  SettingsPreferencesViewModel.swift
//  PlanShift
//
//  Created by Chang Chia ming on 2026/10/21.
//

import Foundation
import Observation

@MainActor
@Observable
final class SettingsPreferencesViewModel {
    private(set) var filters: PreferenceFilters
    private(set) var appearance: AppearanceOption

    private let savePreferences: SaveDefaultPreferencesUseCase
    private let saveAppearance: SaveAppearanceUseCase

    init(
        store: UserDefaultsPreferenceStore,
        appearanceStore: UserDefaultsAppearanceStore? = nil
    ) {
        let appearanceStore =
            appearanceStore ?? UserDefaultsAppearanceStore()

        filters = LoadDefaultPreferencesUseCase(store: store).execute()
        appearance = LoadAppearanceUseCase(
            store: appearanceStore
        ).execute()

        savePreferences = SaveDefaultPreferencesUseCase(store: store)
        saveAppearance = SaveAppearanceUseCase(store: appearanceStore)
    }

    func setBudget(_ budget: BudgetOption) {
        filters.budget = budget
        savePreferences.execute(filters)
    }

    func setSetting(_ setting: SettingPreference) {
        filters.setting = setting
        savePreferences.execute(filters)
    }

    func setMaxDistance(_ distance: DistanceOption) {
        filters.maxDistance = distance
        savePreferences.execute(filters)
    }

    func setAppearance(_ appearance: AppearanceOption) {
        self.appearance = appearance
        saveAppearance.execute(appearance)
    }
}
