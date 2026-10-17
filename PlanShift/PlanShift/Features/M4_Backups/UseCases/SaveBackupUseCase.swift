// Module: M4 – saves a place as a backup (the real implementation of M2's BackupSaving).

import Foundation

/// Saves a place as a backup for an activity's trip and day.
/// M2's bookmark button calls this through the `BackupSaving` protocol.
nonisolated struct SaveBackupUseCase: BackupSaving {
    private let repository: any BackupRepository
    private let calendar: Calendar
    /// Gives the current time. Tests can pass a fixed date.
    private let now: @Sendable () -> Date

    init(
        repository: any BackupRepository,
        calendar: Calendar = .current,
        now: @escaping @Sendable () -> Date = { .now }
    ) {
        self.repository = repository
        self.calendar = calendar
        self.now = now
    }

    func isSaved(placeId: UUID, tripId: UUID) async throws -> Bool {
        try await repository.exists(placeId: placeId, tripId: tripId)
    }

    func save(place: Place, for activity: ItineraryActivity) async throws {
        // Rule: the same place can only be saved once per trip.
        if try await repository.exists(placeId: place.id, tripId: activity.tripId) {
            throw DomainError.duplicateBackup
        }

        let backup = BackupOption(
            tripId: activity.tripId,
            content: .place(place),
            // Keep only the day (midnight), so backups group neatly by day.
            dayDate: calendar.startOfDay(for: activity.date),
            savedAt: now()
        )
        try await repository.save(backup)
    }
}
