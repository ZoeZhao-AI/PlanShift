//
//  ReplaceActivityUseCase.swift
//  PlanShift
//
//  Created by Chang Chia ming on 2026/10/15.
//

import Foundation

nonisolated struct ReplaceActivityUseCase: Sendable {
    private let activityRepository: any ActivityRepository
    private let backupRepository: any BackupRepository

    init(
        activityRepository: any ActivityRepository,
        backupRepository: any BackupRepository
    ) {
        self.activityRepository = activityRepository
        self.backupRepository = backupRepository
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

        guard place.durationMinutes > 0 else {
            throw DomainError.invalidTimeRange
        }

        let endTime = original.startTime.addingTimeInterval(
            TimeInterval(place.durationMinutes) * 60
        )

        let hasConflict = activities.contains {
            $0.id != original.id &&
            $0.startTime < endTime &&
            $0.endTime > original.startTime
        }

        guard !hasConflict else {
            throw DomainError.timeConflict
        }

        var replacement = original
        replacement.name = place.name
        replacement.locationName = place.name
        replacement.latitude = place.latitude
        replacement.longitude = place.longitude
        replacement.setting = place.setting
        replacement.estimatedCost = place.cost
        replacement.endTime = endTime

        let backup = BackupOption(
            tripId: original.tripId,
            content: .activity(original),
            dayDate: original.date
        )

        try await backupRepository.save(backup)

        do {
            try await activityRepository.update(replacement)
        } catch {
            let updateError = error

            do {
                try await backupRepository.delete(id: backup.id)
            } catch {
                throw DomainError.replacementCleanupFailed(
                    updateFailure: String(describing: updateError),
                    cleanupFailure: String(describing: error)
                )
            }

            throw updateError
        }

        return original
    }
}
