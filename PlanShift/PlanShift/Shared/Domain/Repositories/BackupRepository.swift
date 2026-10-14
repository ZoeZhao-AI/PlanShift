// Module: Shared – repository protocol (implemented by M4).

import Foundation

/// Loads and saves backup places.
nonisolated protocol BackupRepository: Sendable {
    /// All backups of a trip, newest first.
    func fetchBackups(tripId: UUID) async throws -> [BackupOption]
    func save(_ backup: BackupOption) async throws
    func delete(id: UUID) async throws
    /// True if this place is already saved as a backup for this trip.
    func exists(placeId: UUID, tripId: UUID) async throws -> Bool
}
