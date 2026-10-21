//
//  LoadAppearanceUseCase.swift
//  PlanShift
//
//  Created by Chang Chia ming on 2026/10/21.
//

import Foundation

@MainActor
struct LoadAppearanceUseCase {
    let store: UserDefaultsAppearanceStore

    func execute() -> AppearanceOption {
        store.load()
    }
}
