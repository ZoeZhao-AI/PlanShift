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

    var trip: Trip?
    var activities: [ItineraryActivity] = []
    var isLoading = false
    var errorMessage: String?

    private let tripRepository: any TripRepository
    private let fetchItineraryUseCase: FetchItineraryUseCase

    init(
        tripRepository: any TripRepository,
        fetchItineraryUseCase: FetchItineraryUseCase
    ) {
        self.tripRepository = tripRepository
        self.fetchItineraryUseCase = fetchItineraryUseCase
    }

    func loadItinerary() async {

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            trip = try await tripRepository.fetchCurrentTrip()

            if let trip = trip {
                activities = try await fetchItineraryUseCase.execute(
                    tripId: trip.id
                )
            } else {
                activities = []
            }

        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
