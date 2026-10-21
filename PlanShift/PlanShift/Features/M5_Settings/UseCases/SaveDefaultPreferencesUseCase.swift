//
//  SaveDefaultPreferencesUseCase.swift
//  PlanShift
//
//  Created by Chang Chia ming on 2026/10/21.
//

import Foundation

@MainActor
struct SaveDefaultPreferencesUseCase {
    let store: UserDefaultsPreferenceStore

    func execute(_ filters: PreferenceFilters) {
        store.save(filters)
    }
}
