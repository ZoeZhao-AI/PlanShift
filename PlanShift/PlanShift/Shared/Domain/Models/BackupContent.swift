//
//  BackupContent.swift
//  PlanShift
//
//  Created by Chang Chia ming on 2026/10/15.
//

import Foundation

nonisolated enum BackupContent: Hashable, Codable, Sendable {
    case place(Place)
    case activity(ItineraryActivity)
}
