//
//  GetAlternatives.swift
//  PlanShift
//
//  Created by Van Dao Le on 15/10/2026.
//

// Module: M2 – use case: load the bundled places and rank them for one affected activity.

import Foundation

/// Loads the bundled places and ranks them for one affected activity.
nonisolated struct GetAlternativesUseCase: Sendable {
    let places: PlaceRepository
    var ranker = AlternativeRanker()

    /// - Throws: `DomainError.noMatchingAlternatives` (→ M2-04), or a `PlacesDatasetError`
    ///   if the built-in data cannot be read.
    func callAsFunction(
        activity: ItineraryActivity,
        disruption: Disruption,
        filters: PreferenceFilters,
        origin: ResolvedOrigin
    ) async throws -> [RankedAlternative] {
        let all = try await places.fetchAllPlaces()
        return try ranker.rank(places: all, activity: activity, disruption: disruption, filters: filters, origin: origin)
    }
}
