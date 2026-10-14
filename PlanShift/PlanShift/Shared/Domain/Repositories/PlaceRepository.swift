// Module: Shared – repository protocol (implemented by M2).

import Foundation

/// Access to the bundled dataset of alternative places.
nonisolated protocol PlaceRepository: Sendable {
    func fetchAllPlaces() async throws -> [Place]
    /// Copies the bundled places into the database on first launch. Safe to call every launch.
    func importBundledPlacesIfNeeded() async throws
}
