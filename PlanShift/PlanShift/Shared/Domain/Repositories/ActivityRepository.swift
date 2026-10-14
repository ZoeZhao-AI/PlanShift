// Module: Shared – repository protocol (implemented by M1).

import Foundation

/// Loads and saves itinerary activities.
nonisolated protocol ActivityRepository: Sendable {
    /// All activities of a trip, sorted by start time.
    func fetchActivities(tripId: UUID) async throws -> [ItineraryActivity]
    /// All activities on the same calendar day as `date`, sorted by start time.
    func fetchActivities(on date: Date) async throws -> [ItineraryActivity]
    func add(_ activity: ItineraryActivity) async throws
    /// Throws `DomainError.activityNotFound` if the activity does not exist.
    func update(_ activity: ItineraryActivity) async throws
    /// Throws `DomainError.activityNotFound` if the activity does not exist.
    func delete(id: UUID) async throws
    /// The first activity starting after `date`, or nil (used by the widget).
    func fetchNextUpcoming(after date: Date) async throws -> ItineraryActivity?
}
