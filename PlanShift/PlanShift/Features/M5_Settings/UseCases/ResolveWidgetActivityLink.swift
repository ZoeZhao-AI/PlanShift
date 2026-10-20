import Foundation

/// Resolves a link within a caller-supplied trip. Selecting that trip belongs to app integration.
nonisolated struct ResolveWidgetActivityLink: Sendable {
    let repository: any ActivityRepository

    /// Nil means an invalid link; a valid link with no matching activity throws activityNotFound.
    /// The repository has no lookup by ID across trips, so this cannot determine whether an
    /// activity was deleted or belongs to a different trip. It never substitutes another activity.
    func execute(url: URL, tripId: UUID) async throws -> ItineraryActivity? {
        try Task.checkCancellation()
        guard let activityId = WidgetActivityLink.activityId(from: url) else { return nil }

        do {
            let activities = try await repository.fetchActivities(tripId: tripId)
            try Task.checkCancellation()
            guard let activity = activities.first(where: { $0.id == activityId && $0.tripId == tripId }) else {
                throw DomainError.activityNotFound
            }
            // A stale widget can still open a stored activity after its start time.
            return activity
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as DomainError {
            throw error
        } catch {
            throw DomainError.persistenceFailure
        }
    }
}
