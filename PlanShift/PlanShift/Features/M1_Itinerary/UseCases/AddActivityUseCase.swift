//
//  AddActivityUseCase.swift
//  PlanShift
//
//  Created by Tianqi Li's Macbook pro on 15/10/2026.
//

import Foundation
// Module: M1 - Itinerary Management

struct AddActivityUseCase {

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

            if activity.startTime < existing.endTime &&
               activity.endTime > existing.startTime {
                throw DomainError.timeConflict
            }
        }

        var newActivity = activity
        newActivity.name = trimmedName

        try await repository.add(newActivity)
    }
}
