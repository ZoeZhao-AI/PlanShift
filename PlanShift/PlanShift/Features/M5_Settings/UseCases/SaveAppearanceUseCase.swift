//
//  SaveAppearanceUseCase.swift
//  PlanShift
//
//  Created by Chang Chia ming on 2026/10/21.
//

import Foundation

@MainActor
struct SaveAppearanceUseCase {
    let store: UserDefaultsAppearanceStore

    func execute(_ appearance: AppearanceOption) {
        store.save(appearance)
    }
}
