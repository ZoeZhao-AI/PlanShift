//
//  FetchItineraryUseCase.swift
//  PlanShift
//
//  Created by Tianqi Li's Macbook pro on 15/10/2026.
//

import Foundation
// Module: M1 - Itinerary Management

struct FetchItineraryUseCase {

    let repository: any ActivityRepository

    func execute(
        tripId: UUID
    ) async throws -> [ItineraryActivity] {

        let activities = try await repository.fetchActivities(
            tripId: tripId
        )

        return activities.sorted {
            $0.startTime < $1.startTime
        }
    }
}
