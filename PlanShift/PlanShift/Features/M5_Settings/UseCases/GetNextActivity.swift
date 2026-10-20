import Foundation

/// The caller supplies the trip; choosing the app/widget's current trip is an integration concern.
nonisolated struct GetNextActivity: Sendable {
    let repository: any ActivityRepository
    var now: @Sendable () -> Date = { .now }

    func execute(tripId: UUID) async throws -> ItineraryActivity? {
        let cutoff = now()
        do {
            let activities = try await repository.fetchActivities(tripId: tripId)
            try Task.checkCancellation()
            // Match fetchNextUpcoming(after:): an activity at the boundary has already started.
            return activities
                .filter { $0.tripId == tripId && $0.startTime > cutoff }
                .min {
                    if $0.startTime == $1.startTime { return $0.id.uuidString < $1.id.uuidString }
                    return $0.startTime < $1.startTime
                }
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as DomainError {
            throw error
        } catch {
            throw DomainError.persistenceFailure
        }
    }
}
