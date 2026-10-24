// Module: M4 – loads one day's activities of a trip (for M4-02 "Replace which activity?").

import Foundation

/// Returns a trip's activities on one calendar day, earliest start first.
nonisolated struct FetchDayActivitiesUseCase: Sendable {
    private let repository: any ActivityRepository
    private let calendar: Calendar

    init(
        repository: any ActivityRepository,
        calendar: Calendar = .current
    ) {
        self.repository = repository
        self.calendar = calendar
    }

    func execute(tripId: UUID, day: Date) async throws -> [ItineraryActivity] {
        // Load the whole trip, then keep only the activities on that day.
        let activities = try await repository.fetchActivities(tripId: tripId)

        return activities
            .filter { calendar.isDate($0.date, inSameDayAs: day) }
            .sorted { $0.startTime < $1.startTime }
    }
}
