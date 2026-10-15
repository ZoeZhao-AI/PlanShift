//
//  RankedAlternative.swift
//  PlanShift
//
//  Created by Van Dao Le on 15/10/2026.
//

// Module: Shared – domain model.

import Foundation

/// One of the top 3 recommended places (M2-03).
nonisolated struct RankedAlternative: Identifiable, Hashable, Sendable {
    /// 1, 2 or 3 (1 = best match).
    let rank: Int
    let place: Place
    /// Straight-line distance from the search origin. `nil` when no trustworthy origin exists.
    let distanceMeters: Double?
    /// Estimated walking time derived from `distanceMeters` (see `DistanceEstimator`). Always an
    /// estimate, never routed data. `nil` whenever `distanceMeters` is `nil`.
    let walkingMinutes: Int?
    let reasons: [ReasonTag]
    /// Weighted ranking score, 0...1. Exposed for tests and debugging, not shown to the user.
    let score: Double

    var id: UUID { place.id }
}
