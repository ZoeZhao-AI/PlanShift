//
//  AppearanceOption.swift
//  PlanShift
//
//  Created by Chang Chia ming on 2026/10/21.
//

import Foundation

nonisolated enum AppearanceOption: String, CaseIterable, Identifiable, Sendable {
    case automatic
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .automatic: "Automatic"
        case .light: "Light"
        case .dark: "Dark"
        }
    }
}
