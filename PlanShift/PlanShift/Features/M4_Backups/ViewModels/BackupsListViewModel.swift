// Module: M4 – state for M4-01 Backups List: day sections, summary, delete.

import Foundation
import Observation

/// One backup row, ready to show. The view never needs to look inside `BackupContent`.
nonisolated struct BackupRow: Identifiable, Hashable, Sendable {
    /// Same id as the `BackupOption`, so delete can use it.
    let id: UUID
    let title: String
    /// Short labels, e.g. ["Indoor", "Free entry", "~1.5 hrs"].
    let tags: [String]
    /// Image in Assets.xcassets, or nil when there is none.
    let imageName: String?
    /// True when this backup is the original activity that was replaced ("Original plan").
    let isFromReplacedActivity: Bool
}

extension BackupRow {
    /// Builds the display row for a backup. Also used by M4-02 for its backup card.
    init(backup: BackupOption) {
        switch backup.content {
        case .place(let place):
            self.init(
                id: backup.id,
                title: place.name,
                tags: Self.tags(setting: place.setting, cost: place.cost, minutes: place.durationMinutes),
                imageName: place.imageName.isEmpty ? nil : place.imageName,
                isFromReplacedActivity: false
            )
        case .activity(let activity):
            self.init(
                id: backup.id,
                title: activity.name,
                tags: Self.tags(
                    setting: activity.setting,
                    cost: activity.estimatedCost,
                    minutes: Int(activity.endTime.timeIntervalSince(activity.startTime) / 60)
                ),
                // Activities have no image in the dataset.
                imageName: nil,
                isFromReplacedActivity: true
            )
        }
    }

    /// e.g. ["Indoor", "Free entry", "~1.5 hrs"]. Reuses M2's cost and duration formats.
    private static func tags(setting: ActivitySetting, cost: Decimal, minutes: Int) -> [String] {
        var tags = [setting.title]
        tags.append(cost == 0 ? "Free entry" : M2Formatting.cost(cost))
        if minutes > 0 {
            tags.append(M2Formatting.duration(minutes: minutes))
        }
        return tags
    }
}

/// One day of the list, e.g. header "DAY 1 · FRI 13 NOV" and its rows.
nonisolated struct BackupDaySection: Identifiable, Hashable, Sendable {
    let dayDate: Date
    let header: String
    let rows: [BackupRow]

    var id: Date { dayDate }
}

@MainActor
@Observable
final class BackupsListViewModel {
    private(set) var isLoading = false
    private(set) var sections: [BackupDaySection] = []
    private(set) var errorMessage: String?
    /// The trip shown, kept for the summary text.
    private(set) var trip: Trip?

    /// The loaded backups by id, so a tapped row can be opened in M4-02.
    @ObservationIgnored private var backupsById: [UUID: BackupOption] = [:]

    private let fetchBackups: FetchBackupsUseCase
    private let removeBackup: RemoveBackupUseCase
    private let calendar: Calendar

    /// Total number of backups across all days.
    var totalCount: Int {
        sections.reduce(0) { $0 + $1.rows.count }
    }

    var isEmpty: Bool {
        sections.isEmpty
    }

    /// "4 saved for Sydney Trip" or "1 saved for Sydney Trip". Empty before a trip is loaded.
    var summaryText: String {
        guard let trip else { return "" }
        return "\(totalCount) saved for \(trip.name)"
    }

    init(
        fetchBackups: FetchBackupsUseCase,
        removeBackup: RemoveBackupUseCase,
        calendar: Calendar = .current
    ) {
        self.fetchBackups = fetchBackups
        self.removeBackup = removeBackup
        self.calendar = calendar
    }

    func load(trip: Trip) async {
        self.trip = trip
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let groups = try await fetchBackups.execute(tripId: trip.id)
            sections = groups.map { makeSection(from: $0, trip: trip) }
            let backups = groups.flatMap(\.backups)
            backupsById = Dictionary(uniqueKeysWithValues: backups.map { ($0.id, $0) })
        } catch {
            // Keep whatever was shown before and tell the user.
            errorMessage = "Your backups could not be loaded. Please try again."
        }
    }

    func delete(backupId: UUID) async {
        errorMessage = nil

        do {
            try await removeBackup.execute(id: backupId)
        } catch {
            // The backup is still saved, so leave the list as it is.
            errorMessage = error.localizedDescription
            return
        }

        backupsById[backupId] = nil

        // Remove the row, then drop any day that is now empty.
        sections = sections.compactMap { section in
            let rows = section.rows.filter { $0.id != backupId }
            guard !rows.isEmpty else { return nil }
            return BackupDaySection(dayDate: section.dayDate, header: section.header, rows: rows)
        }
    }

    /// The full backup behind a row, e.g. to open M4-02 "Use a backup". Nil if it is no longer loaded.
    func backup(for rowId: UUID) -> BackupOption? {
        backupsById[rowId]
    }

    func clearError() {
        errorMessage = nil
    }

    // MARK: - Building display models

    private func makeSection(from group: BackupDayGroup, trip: Trip) -> BackupDaySection {
        BackupDaySection(
            dayDate: group.dayDate,
            header: header(for: group.dayDate, trip: trip),
            rows: group.backups.map(BackupRow.init(backup:))
        )
    }

    /// "DAY 1 · FRI 13 NOV". The trip's start date is Day 1.
    private func header(for dayDate: Date, trip: Trip) -> String {
        let start = calendar.startOfDay(for: trip.startDate)
        let day = calendar.startOfDay(for: dayDate)
        let daysFromStart = calendar.dateComponents([.day], from: start, to: day).day ?? 0

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        // Fixed English locale so the header always looks like the design.
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE d MMM"

        return "DAY \(daysFromStart + 1) · \(formatter.string(from: day).uppercased())"
    }
}
