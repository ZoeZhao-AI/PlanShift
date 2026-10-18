//
//  ItineraryViewModel.swift
//  PlanShift
//
//  Created by Tianqi Li's Macbook pro on 18/10/2026.
//


import Foundation
import Observation

// Module: M1 - Itinerary Management

@MainActor
@Observable
final class ItineraryViewModel {

    var activities: [ItineraryActivity] = []
    var isLoading = false
    var errorMessage: String?

    private let fetchItineraryUseCase: FetchItineraryUseCase

    init(fetchItineraryUseCase: FetchItineraryUseCase) {
        self.fetchItineraryUseCase = fetchItineraryUseCase
    }

    func loadActivities(tripId: UUID) async {

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            activities = try await fetchItineraryUseCase.execute(
                tripId: tripId
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
