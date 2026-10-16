//
//  RecommendationFlowViewModel.swift
//  PlanShift
//
//  Created by Van Dao Le on 15/10/2026.
//

// Module: M2 – state for the whole disruption flow (M2-01 → M2-04): stored state and initialiser.
//
// The behaviour is split by use case into extensions, so each use case can be read on its own:
//   +Disruption  choose a disruption and the starting filters
//   +Search      rank alternatives and hand one to Replace
//   +Location    ask for / track location permission
//   +Backup      bookmark an alternative

import Foundation
import Observation

/// One instance lives for one open disruption sheet. Views read it; only the use-case extensions change it.
/// Keeping filters here (not in each screen) means Back / Adjust filters never loses a choice.
@MainActor
@Observable
final class RecommendationFlowViewModel {
    enum Phase: Equatable {
        case idle
        case loading
        case results([RankedAlternative])
        /// M2-04 – nothing matched the filters.
        case empty
        case failed(String)
    }

    // Inputs
    let activity: ItineraryActivity
    var disruption: Disruption?
    var filters: PreferenceFilters

    // Outputs (written by the use-case extensions, read by the views)
    var phase: Phase = .idle
    var origin: ResolvedOrigin
    var locationStatus: LocationAuthorizationStatus
    /// Start date of the activity's trip, when known; lets the screens say "Day 1" instead of a date.
    var tripStartDate: Date?
    var savedPlaceIds: Set<UUID> = []
    var busyPlaceIds: Set<UUID> = []
    var toast: ToastMessage?

    // Navigation flags (local to the sheet; no shared router state is touched)
    var showsResults = false
    var isShowingLocationPrePrompt = false
    /// Set when the user taps Replace; the results screen pushes M3-01 for this place.
    var replacementTarget: Place?

    // Dependencies and bookkeeping (not observed by views)
    @ObservationIgnored let getAlternatives: GetAlternativesUseCase
    @ObservationIgnored let backups: BackupSaving
    @ObservationIgnored let location: LocationProviding
    @ObservationIgnored let trips: TripRepository?
    @ObservationIgnored let defaults = ApplyDisruptionDefaults()
    @ObservationIgnored let baseFilters: PreferenceFilters
    @ObservationIgnored var hasDecidedLocationPrompt = false
    @ObservationIgnored var searchGeneration = 0

    init(
        activity: ItineraryActivity,
        getAlternatives: GetAlternativesUseCase,
        backups: BackupSaving,
        location: LocationProviding,
        trips: TripRepository? = nil,
        baseFilters: PreferenceFilters = PreferenceFilters()
    ) {
        self.activity = activity
        self.getAlternatives = getAlternatives
        self.backups = backups
        self.location = location
        self.trips = trips
        self.baseFilters = baseFilters
        self.filters = baseFilters
        self.locationStatus = location.authorizationStatus
        self.origin = OriginResolver.resolve(device: nil, activity: activity)
    }
}
