// Module: Shared – domain model.

import Foundation

/// A place the traveller saved as a backup for one day of the trip.
nonisolated struct BackupOption: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    var tripId: UUID
    var place: Place
    /// The trip day this backup is for.
    var dayDate: Date
    var savedAt: Date

    init(id: UUID = UUID(), tripId: UUID, place: Place, dayDate: Date, savedAt: Date = .now) {
        self.id = id
        self.tripId = tripId
        self.place = place
        self.dayDate = dayDate
        self.savedAt = savedAt
    }
}
