// Module: Shared – data layer (M4): maps BackupEntity <-> BackupOption.

import Foundation

/// Converts between the Core Data row and the domain model.
/// Call it only inside the context's `perform`, like any other use of `BackupEntity`.
nonisolated enum BackupEntityMapper {
    enum Kind: String {
        case place
        case activity
    }

    enum MappingError: Error {
        case unknownKind(String)
        case kindMismatch
    }

    static func kind(of content: BackupContent) -> Kind {
        switch content {
        case .place: .place
        case .activity: .activity
        }
    }

    static func placeId(of content: BackupContent) -> UUID? {
        guard case .place(let place) = content else { return nil }
        return place.id
    }

    /// Copies every field of `backup` onto `entity` (used for both insert and update).
    static func apply(_ backup: BackupOption, to entity: BackupEntity) throws {
        entity.id = backup.id
        entity.tripId = backup.tripId
        entity.dayDate = backup.dayDate
        entity.savedAt = backup.savedAt
        entity.kind = kind(of: backup.content).rawValue
        entity.placeId = placeId(of: backup.content)
        entity.contentData = try JSONEncoder().encode(backup.content)
    }

    static func toDomain(_ entity: BackupEntity) throws -> BackupOption {
        guard let storedKind = Kind(rawValue: entity.kind) else {
            throw MappingError.unknownKind(entity.kind)
        }
        let content = try JSONDecoder().decode(
            BackupContent.self,
            from: entity.contentData
        )
        guard kind(of: content) == storedKind else {
            throw MappingError.kindMismatch
        }

        return BackupOption(
            id: entity.id,
            tripId: entity.tripId,
            content: content,
            dayDate: entity.dayDate,
            savedAt: entity.savedAt
        )
    }
}
