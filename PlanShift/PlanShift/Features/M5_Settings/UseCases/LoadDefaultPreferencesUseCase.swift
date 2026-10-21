//
//  LoadDefaultPreferencesUseCase.swift
//  PlanShift
//
//  Created by Chang Chia ming on 2026/10/21.
//

import Foundation

@MainActor
struct LoadDefaultPreferencesUseCase {
    let store: UserDefaultsPreferenceStore

    func execute() -> PreferenceFilters {
        store.load()
    }
}
