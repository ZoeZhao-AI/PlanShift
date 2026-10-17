// Module: Shared – data layer (M4): Core Data class for the BackupEntity entity.

import CoreData
import Foundation

/// Written by hand (codegen is off for this entity) so it can be `nonisolated`:
/// it is only touched inside `perform` on a background context, never on the main actor.
/// Only `CoreDataBackupRepository` and `BackupEntityMapper` use it.
@objc(BackupEntity)
nonisolated final class BackupEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var tripId: UUID
    @NSManaged var dayDate: Date
    @NSManaged var savedAt: Date
    /// "place" or "activity", see `BackupEntityMapper.Kind`.
    @NSManaged var kind: String
    /// Only set for place backups, so `exists` can query it directly.
    @NSManaged var placeId: UUID?
    /// The `BackupContent` as JSON, because places are not stored in Core Data.
    @NSManaged var contentData: Data

    @nonobjc static func fetchRequest() -> NSFetchRequest<BackupEntity> {
        NSFetchRequest<BackupEntity>(entityName: "BackupEntity")
    }
}
