// Module: Shared – domain model.

import Foundation

/// One of the top 3 recommended places (M2-03).
nonisolated struct RankedAlternative: Identifiable, Hashable, Sendable {
    /// 1, 2 or 3 (1 = best match).
    let rank: Int
    let place: Place
    let distanceMeters: Double
    let walkingMinutes: Int
    let reasons: [ReasonTag]

    var id: UUID { place.id }
}
