// Module: Shared – data layer (M4): BackupRepository backed by Core Data.

import CoreData
import Foundation

/// Stores backups as `BackupEntity` rows and only ever returns `BackupOption` values.
///
/// All work runs on one private background context through `perform`, so calls from
/// any async code are safe and run one at a time (two saves of the same id cannot
/// both insert). Saved changes reach the view context because
/// `PersistenceController` turns on `automaticallyMergesChangesFromParent`.
///
/// TODO(integration): add the BackupEntity -> TripEntity relationship once M1's
/// TripEntity is on develop. Until then `tripId` is a plain UUID attribute.
nonisolated final class CoreDataBackupRepository: BackupRepository {
    private let context: NSManagedObjectContext

    init(container: NSPersistentContainer) {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        self.context = context
    }

    func fetchBackups(tripId: UUID) async throws -> [BackupOption] {
        try await perform { context in
            let request = BackupEntity.fetchRequest()
            request.predicate = NSPredicate(
                format: "tripId == %@",
                tripId as CVarArg
            )
            request.sortDescriptors = [
                NSSortDescriptor(key: "savedAt", ascending: false)
            ]
            return try context.fetch(request).map(BackupEntityMapper.toDomain)
        }
    }

    func save(_ backup: BackupOption) async throws {
        try await perform { context in
            let entity = try Self.entity(id: backup.id, in: context)
                ?? Self.insertEntity(in: context)
            try BackupEntityMapper.apply(backup, to: entity)
            try context.save()
        }
    }

    func delete(id: UUID) async throws {
        try await perform { context in
            guard let entity = try Self.entity(id: id, in: context) else {
                return
            }
            context.delete(entity)
            try context.save()
        }
    }

    func exists(placeId: UUID, tripId: UUID) async throws -> Bool {
        try await perform { context in
            let request = BackupEntity.fetchRequest()
            request.predicate = NSPredicate(
                format: "tripId == %@ AND kind == %@ AND placeId == %@",
                tripId as CVarArg,
                BackupEntityMapper.Kind.place.rawValue,
                placeId as CVarArg
            )
            request.fetchLimit = 1
            return try context.count(for: request) > 0
        }
    }

    // MARK: - Helpers

    /// Runs `work` on the background context and turns any failure into
    /// `DomainError.persistenceFailure`. Unsaved changes are rolled back so a
    /// failed call does not leak into the next one.
    private func perform<T: Sendable>(
        _ work: @escaping (NSManagedObjectContext) throws -> T
    ) async throws -> T {
        let context = self.context
        do {
            return try await context.perform {
                do {
                    return try work(context)
                } catch {
                    context.rollback()
                    throw error
                }
            }
        } catch {
            throw DomainError.persistenceFailure
        }
    }

    /// Looks the entity up in this context's own model instead of using
    /// `BackupEntity(context:)`, which is ambiguous when more than one copy of the
    /// model is loaded (e.g. several in-memory stores in tests).
    private static func insertEntity(
        in context: NSManagedObjectContext
    ) throws -> BackupEntity {
        guard let model = context.persistentStoreCoordinator?.managedObjectModel,
              let description = model.entitiesByName["BackupEntity"] else {
            throw DomainError.persistenceFailure
        }
        return BackupEntity(entity: description, insertInto: context)
    }

    private static func entity(
        id: UUID,
        in context: NSManagedObjectContext
    ) throws -> BackupEntity? {
        let request = BackupEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
}
