// Module: M4 – state for M4-02 Use a Backup: pick a day, pick the activity to replace.

import Foundation
import Observation

/// One day button in the day selector, e.g. "Day 2" / "Sat 14".
nonisolated struct UseBackupDay: Identifiable, Hashable, Sendable {
    /// Midnight of the day.
    let date: Date
    let title: String
    let shortDate: String

    var id: Date { date }
}

/// One activity that can be replaced, ready to show.
nonisolated struct ActivityChoiceRow: Identifiable, Hashable, Sendable {
    let id: UUID
    let title: String
    /// e.g. "09:00 – 12:00".
    let timeRange: String
    let setting: ActivitySetting
}

@MainActor
@Observable
final class UseBackupViewModel {
    let backup: BackupOption
    /// The backup card at the top, built the same way as on the Backups list.
    let backupRow: BackupRow

    private(set) var days: [UseBackupDay] = []
    private(set) var selectedDay: Date?
    private(set) var activityRows: [ActivityChoiceRow] = []
    private(set) var selectedActivityId: UUID?
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    /// Shown instead of the list when the chosen day has no activities.
    let emptyDayMessage = "No activities planned for this day."

    /// The full activities of the selected day, so Continue can hand one to M3.
    @ObservationIgnored private var activities: [ItineraryActivity] = []
    @ObservationIgnored private var tripId: UUID?

    private let fetchDayActivities: FetchDayActivitiesUseCase
    private let calendar: Calendar

    init(
        backup: BackupOption,
        fetchDayActivities: FetchDayActivitiesUseCase,
        calendar: Calendar = .current
    ) {
        self.backup = backup
        self.backupRow = BackupRow(backup: backup)
        self.fetchDayActivities = fetchDayActivities
        self.calendar = calendar
    }

    /// The place to swap in. Nil for an "Original plan" backup, which M3 cannot accept yet.
    var place: Place? {
        guard case .place(let place) = backup.content else { return nil }
        return place
    }

    /// Explains why an "Original plan" backup cannot continue. Nil for place backups.
    var unsupportedMessage: String? {
        place == nil ? "Restoring an original plan isn't available yet." : nil
    }

    /// True when the selected day finished loading and has nothing to replace.
    var isDayEmpty: Bool {
        selectedDay != nil && !isLoading && errorMessage == nil && activityRows.isEmpty
    }

    var selectedActivity: ItineraryActivity? {
        activities.first { $0.id == selectedActivityId }
    }

    var canContinue: Bool {
        place != nil && selectedActivity != nil && !isLoading
    }

    /// Builds the trip's days and opens the backup's own day (or Day 1 if it is outside the trip).
    func load(trip: Trip) async {
        tripId = trip.id
        days = makeDays(for: trip)

        let backupDay = calendar.startOfDay(for: backup.dayDate)
        let firstDay = days.contains { $0.date == backupDay } ? backupDay : days.first?.date
        guard let firstDay else { return }
        await selectDay(firstDay)
    }

    /// Switches day, clears the selection and loads that day's activities.
    func selectDay(_ day: Date) async {
        guard let tripId else { return }
        selectedDay = day
        selectedActivityId = nil
        activities = []
        activityRows = []
        errorMessage = nil
        isLoading = true

        do {
            let loaded = try await fetchDayActivities.execute(tripId: tripId, day: day)
            // The user may have tapped another day while this one was loading.
            guard selectedDay == day else { return }
            activities = loaded
            activityRows = loaded.map(makeRow)
        } catch {
            guard selectedDay == day else { return }
            errorMessage = "This day's activities could not be loaded. Please try again."
        }
        isLoading = false
    }

    func selectActivity(id: UUID) {
        guard activities.contains(where: { $0.id == id }) else { return }
        selectedActivityId = id
    }

    func clearError() {
        errorMessage = nil
    }

    // MARK: - Building display models

    /// One entry per trip day, e.g. "Day 1" / "Fri 13".
    private func makeDays(for trip: Trip) -> [UseBackupDay] {
        let start = calendar.startOfDay(for: trip.startDate)
        let end = calendar.startOfDay(for: trip.endDate)
        let count = (calendar.dateComponents([.day], from: start, to: end).day ?? 0) + 1

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        // Fixed English locale so it always matches the design.
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE d"

        return (0..<max(count, 0)).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            return UseBackupDay(date: date, title: "Day \(offset + 1)", shortDate: formatter.string(from: date))
        }
    }

    private func makeRow(from activity: ItineraryActivity) -> ActivityChoiceRow {
        ActivityChoiceRow(
            id: activity.id,
            title: activity.name,
            timeRange: M2Formatting.timeRange(of: activity, calendar: calendar),
            setting: activity.setting
        )
    }
}
