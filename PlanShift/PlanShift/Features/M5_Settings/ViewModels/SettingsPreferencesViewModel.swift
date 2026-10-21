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

    private let savePreferences: SaveDefaultPreferencesUseCase

    init(store: UserDefaultsPreferenceStore) {
        filters = LoadDefaultPreferencesUseCase(store: store).execute()
        savePreferences = SaveDefaultPreferencesUseCase(store: store)
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
}
