//
//  RecommendationFlowViewModel+Location.swift
//  PlanShift
//
//  Created by Van Dao Le on 15/10/2026.
//

// Module: M2 – use case: ask for location permission only when needed, and track it.

import Foundation

extension RecommendationFlowViewModel {
    /// One line under the filters: where "near" is measured from.
    var originDescription: String {
        if locationStatus.isAuthorized { return "Near your location" }
        switch OriginResolver.resolve(device: nil, activity: activity).source {
        case .plannedActivity: return "Near your planned activity · \(activity.locationName)"
        default: return "No location available · distance filter is off"
        }
    }

    /// True when the "Location is off" banner should show above the results.
    var showsLocationDeniedBanner: Bool { locationStatus.isBlocked }

    /// "Allow location": now (and only now) iOS shows its own permission dialog.
    func allowLocation() async {
        hasDecidedLocationPrompt = true
        isShowingLocationPrePrompt = false
        locationStatus = await location.requestWhenInUseAuthorization()
        await search()
    }

    /// "Not now": continue with the planned activity as origin.
    func declineLocation() async {
        hasDecidedLocationPrompt = true
        isShowingLocationPrePrompt = false
        await search()
    }

    /// The sheet was swiped away without a choice: same as "Not now".
    func locationPrePromptDismissed() async {
        guard !hasDecidedLocationPrompt else { return }
        await declineLocation()
    }

    /// Re-reads the permission (e.g. after returning from iOS Settings). Re-ranks if the user
    /// just switched location on while looking at results.
    func refreshLocationStatus() {
        let previous = locationStatus
        locationStatus = location.authorizationStatus
        if previous != locationStatus, locationStatus.isAuthorized, case .results = phase {
            Task { await search() }
        }
    }
}
