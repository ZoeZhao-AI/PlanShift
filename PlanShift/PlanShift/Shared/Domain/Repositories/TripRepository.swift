// Module: Shared – repository protocol (implemented by M1).

import Foundation

/// Loads and saves trips. Use cases depend on this protocol, never on Core Data.
/// `Sendable` so implementations can be used safely from async code.
nonisolated protocol TripRepository: Sendable {
    /// The trip currently being planned or travelled, or nil if there is none.
    func fetchCurrentTrip() async throws -> Trip?
    func createTrip(_ trip: Trip) async throws
    func updateTrip(_ trip: Trip) async throws
}
