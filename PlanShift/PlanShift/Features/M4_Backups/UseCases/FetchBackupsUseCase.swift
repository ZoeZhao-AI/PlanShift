// Module: M4 – loads a trip's backups grouped by day.

import Foundation

/// All backups saved for one day of the trip.
nonisolated struct BackupDayGroup: Identifiable, Hashable, Sendable {
    /// Midnight of the day these backups belong to.
    let dayDate: Date
    /// Newest saved first.
    let backups: [BackupOption]

    var id: Date { dayDate }
}

/// Loads a trip's backups and groups them by day, ready for the Backups list.
nonisolated struct FetchBackupsUseCase: Sendable {
    private let repository: any BackupRepository
    private let calendar: Calendar

    init(
        repository: any BackupRepository,
        calendar: Calendar = .current
    ) {
        self.repository = repository
        self.calendar = calendar
    }

    func execute(tripId: UUID) async throws -> [BackupDayGroup] {
        let backups = try await repository.fetchBackups(tripId: tripId)

        // Put each backup in a bucket keyed by the start of its day.
        let byDay = Dictionary(grouping: backups) { backup in
            calendar.startOfDay(for: backup.dayDate)
        }

        // Earliest day first; inside a day, newest saved first.
        return byDay.keys.sorted().map { day in
            BackupDayGroup(
                dayDate: day,
                backups: byDay[day, default: []].sorted { $0.savedAt > $1.savedAt }
            )
        }
    }
}
