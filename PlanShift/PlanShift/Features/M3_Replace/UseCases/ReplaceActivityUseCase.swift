//
//  ReplaceActivityUseCase.swift
//  PlanShift
//
//  Created by Chang Chia ming on 2026/10/15.
//

import Foundation

nonisolated struct ReplaceActivityUseCase: Sendable {
    private let activityRepository: any ActivityRepository

    init(activityRepository: any ActivityRepository) {
        self.activityRepository = activityRepository
    }

    func execute(
        activity: ItineraryActivity,
        with place: Place
    ) async throws -> ItineraryActivity {
        let activities = try await activityRepository.fetchActivities(
            tripId: activity.tripId
        )

        guard let original = activities.first(
            where: { $0.id == activity.id }
        ) else {
            throw DomainError.activityNotFound
        }

        var replacement = original
        replacement.name = place.name
        replacement.locationName = place.name
        replacement.latitude = place.latitude
        replacement.longitude = place.longitude
        replacement.setting = place.setting
        replacement.estimatedCost = place.cost

        try await activityRepository.update(replacement)

        return original
    }
}
