//
//  UpdateActivityUseCase.swift
//  PlanShift
//
//  Created by Tianqi Li's Macbook pro on 15/10/2026.
//

import Foundation
// Module: M1 - Itinerary Management

struct UpdateActivityUseCase {

    let repository: any ActivityRepository

    func execute(
        activity: ItineraryActivity
    ) async throws {

        let trimmedName = activity.name.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmedName.isEmpty else {
            throw DomainError.emptyName
        }

        guard activity.endTime > activity.startTime else {
            throw DomainError.invalidTimeRange
        }

        let calendar = Calendar.current

        guard calendar.isDate(
            activity.date,
            inSameDayAs: activity.startTime
        ),
        calendar.isDate(
            activity.date,
            inSameDayAs: activity.endTime
        ) else {
            throw DomainError.invalidTimeRange
        }

        let existingActivities = try await repository.fetchActivities(
            tripId: activity.tripId
        )

        for existing in existingActivities {

            // Exclude the activity being updated.
            if existing.id == activity.id {
                continue
            }

            if activity.startTime < existing.endTime &&
               activity.endTime > existing.startTime {
                throw DomainError.timeConflict
            }
        }

        var updatedActivity = activity
        updatedActivity.name = trimmedName

        try await repository.update(updatedActivity)
    }
}
