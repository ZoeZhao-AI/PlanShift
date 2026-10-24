//
//  RecommendationFlowViewModel+Search.swift
//  PlanShift
//
//  Created by Van Dao Le on 15/10/2026.
//

// Module: M2 – use case: rank alternatives and hand the chosen one to Replace (M2-03 / M2-04).

import Foundation

extension RecommendationFlowViewModel {
    /// Tap on "Show alternatives". Shows the location pre-prompt first if iOS has never asked.
    func showAlternatives() async {
        guard disruption != nil else { return }
        refreshLocationStatus()
        if locationStatus == .notDetermined && !hasDecidedLocationPrompt {
            isShowingLocationPrePrompt = true
            return
        }
        await search()
    }

    /// Resolves the origin, ranks the places and publishes `phase` (.results, .empty or .failed).
    /// A newer search supersedes an older one that is still running.
    func search() async {
        guard let disruption else { return }
        searchGeneration += 1
        let generation = searchGeneration
        phase = .loading
        showsResults = true

        locationStatus = location.authorizationStatus
        let device = locationStatus.isAuthorized ? await location.currentLocation() : nil
        let resolved = OriginResolver.resolve(device: device, activity: activity)

        let newPhase: Phase
        do {
            let alternatives = try await getAlternatives(
                activity: activity, disruption: disruption, filters: filters, origin: resolved
            )
            newPhase = .results(alternatives)
            let saved = try? await savedIds(in: alternatives)
            guard generation == searchGeneration else { return }
            savedPlaceIds = saved ?? []
        } catch DomainError.noMatchingAlternatives {
            newPhase = .empty
        } catch {
            newPhase = .failed(error.localizedDescription)
        }
        guard generation == searchGeneration else { return } // a newer search superseded this one
        origin = resolved
        phase = newPhase
    }

    /// Replace → hands (activity, place) to M3-01. Nothing is saved here.
    func replace(with alternative: RankedAlternative) {
        guard replacementTarget == nil else { return }
        replacementTarget = alternative.place
    }
}
