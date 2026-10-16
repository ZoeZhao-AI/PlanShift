//
//  ApplyDisruptionDefaults.swift
//  PlanShift
//
//  Created by Van Dao Le on 15/10/2026.
//

// Module: M2 – initial filters for each manually selected disruption.

import Foundation

/// Turns a disruption into sensible starting filters for M2-02.
/// "Rainy weather" only sets Indoor as a preference; it is **not** a weather observation.
nonisolated struct ApplyDisruptionDefaults: Sendable {
    func filters(for disruption: Disruption, base: PreferenceFilters = PreferenceFilters()) -> PreferenceFilters {
        var filters = base
        switch disruption {
        case .rainyWeather:
            filters.setting = .indoor
        case .attractionClosed:
            break // similarity to the original is handled by ranking, not by a hard filter
        case .transportDelay:
            filters.maxDistance = .oneKm
        case .runningOutOfTime:
            filters.duration = .underOneHour
        }
        return filters
    }

    /// Helper text under the filters on M2-02, or `nil` if nothing was pre-set.
    func note(for disruption: Disruption) -> String? {
        switch disruption {
        case .rainyWeather: "Set to Indoor because of rain. Change it anytime."
        case .attractionClosed: "We'll look for something similar to your original plan."
        case .transportDelay: "Distance set to 1 km so you can stay close by."
        case .runningOutOfTime: "Duration set to under 1 hour for a quicker visit."
        }
    }
}
