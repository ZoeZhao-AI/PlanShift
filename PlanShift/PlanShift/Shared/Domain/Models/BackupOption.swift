// Module: Shared – domain model.

import Foundation

nonisolated struct BackupOption: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    var tripId: UUID
    var content: BackupContent
    var dayDate: Date
    var savedAt: Date

    init(
        id: UUID = UUID(),
        tripId: UUID,
        content: BackupContent,
        dayDate: Date,
        savedAt: Date = .now
    ) {
        self.id = id
        self.tripId = tripId
        self.content = content
        self.dayDate = dayDate
        self.savedAt = savedAt
    }
}
