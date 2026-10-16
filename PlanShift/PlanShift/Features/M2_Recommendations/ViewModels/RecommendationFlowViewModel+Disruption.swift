//
//  RecommendationFlowViewModel+Disruption.swift
//  PlanShift
//
//  Created by Van Dao Le on 15/10/2026.
//

// Module: M2 – use case: choose a disruption and get the starting filters (M2-01 / M2-02).

import Foundation

extension RecommendationFlowViewModel {
    /// "Day 1" when the trip is known, else a date like "Sat 14 Nov".
    var dayLabel: String { M2Formatting.dayLabel(for: activity, tripStart: tripStartDate) }

    /// Loads the activity's trip (if a `TripRepository` is available) to resolve the day number.
    func loadTripContext() async {
        guard tripStartDate == nil, let trips,
              let trip = try? await trips.fetchCurrentTrip(), trip.id == activity.tripId else { return }
        tripStartDate = trip.startDate
    }

    /// The user tapped a disruption card: remember it and pre-set the filters.
    func select(_ disruption: Disruption) {
        self.disruption = disruption
        filters = defaults.filters(for: disruption, base: baseFilters)
    }

    /// "Reset": back to the suggested filters for the chosen disruption.
    func resetFilters() {
        guard let disruption else { filters = baseFilters; return }
        filters = defaults.filters(for: disruption, base: baseFilters)
    }

    /// Helper text under the filters (e.g. "Set to Indoor because of rain.").
    var defaultsNote: String? { disruption.flatMap(defaults.note(for:)) }
}
