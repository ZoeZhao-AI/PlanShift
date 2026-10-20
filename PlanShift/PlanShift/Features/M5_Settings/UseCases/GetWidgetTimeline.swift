import Foundation

/// Reads the current trip selected by the repository; it does not choose a trip itself.
nonisolated struct GetWidgetTimeline: Sendable {
    let trips: any TripRepository
    let activities: any ActivityRepository
    var now: @Sendable () -> Date = { .now }

    func execute() async throws -> WidgetActivityTimeline {
        do {
            try Task.checkCancellation()
            let trip = try await trips.fetchCurrentTrip()
            try Task.checkCancellation()
            guard let trip else { return .empty(now: now()) }

            let items = try await activities.fetchActivities(tripId: trip.id)
            try Task.checkCancellation()
            // Read the clock after loading so activities that started during I/O are excluded.
            return .make(activities: items, tripId: trip.id, now: now())
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as DomainError {
            throw error
        } catch {
            throw DomainError.persistenceFailure
        }
    }
}
