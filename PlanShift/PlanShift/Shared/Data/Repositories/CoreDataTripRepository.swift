
import CoreData
import Foundation

// Module: M1 - Core Data Trip Repository

nonisolated enum M1TripPersistenceError: LocalizedError {
    case anotherTripAlreadyExists
    case tripNotFound
    case invalidStoredTrip
    case multipleTripsFound

    var errorDescription: String? {
        switch self {
        case .anotherTripAlreadyExists:
            return "A trip already exists. Please edit the current trip."

        case .tripNotFound:
            return "The trip could not be found."

        case .invalidStoredTrip:
            return "The saved trip contains incomplete data."

        case .multipleTripsFound:
            return "More than one trip was found. The current trip cannot be determined."
        }
    }
}

@MainActor
final class CoreDataTripRepository: TripRepository {

    private let context: NSManagedObjectContext

    init(container: NSPersistentContainer) {
        context = NSManagedObjectContext(
            concurrencyType: .mainQueueConcurrencyType
        )

        context.persistentStoreCoordinator =
            container.persistentStoreCoordinator

        context.mergePolicy =
            NSMergeByPropertyObjectTrumpMergePolicy

        context.automaticallyMergesChangesFromParent = true
    }

    @MainActor
    func fetchCurrentTrip() async throws -> Trip? {
        guard let entity = try fetchStoredTrip() else {
            return nil
        }

        guard let id = entity.id,
              let name = entity.name,
              let startDate = entity.startDate,
              let endDate = entity.endDate else {
            throw M1TripPersistenceError.invalidStoredTrip
        }

        return Trip(
            id: id,
            name: name,
            startDate: startDate,
            endDate: endDate
        )
    }

    @MainActor
    func createTrip(_ trip: Trip) async throws {
        let entity: TripEntity

        if let existing = try fetchStoredTrip() {
            guard existing.id == trip.id else {
                throw M1TripPersistenceError.anotherTripAlreadyExists
            }

            entity = existing
        } else {
            entity = TripEntity(context: context)
        }

        apply(trip, to: entity)
        try saveChanges()
    }

    @MainActor
    func updateTrip(_ trip: Trip) async throws {
        guard let entity = try fetchStoredTrip(),
              entity.id == trip.id else {
            throw M1TripPersistenceError.tripNotFound
        }

        apply(trip, to: entity)
        try saveChanges()
    }

    private func fetchStoredTrip() throws -> TripEntity? {
        let request = NSFetchRequest<TripEntity>(
            entityName: "TripEntity"
        )

        request.fetchLimit = 2
        request.shouldRefreshRefetchedObjects = true

        let entities = try context.fetch(request)

        guard entities.count <= 1 else {
            throw M1TripPersistenceError.multipleTripsFound
        }

        return entities.first
    }

    private func apply(
        _ trip: Trip,
        to entity: TripEntity
    ) {
        entity.id = trip.id
        entity.name = trip.name
        entity.startDate = trip.startDate
        entity.endDate = trip.endDate
    }

    private func saveChanges() throws {
        guard context.hasChanges else {
            return
        }

        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }
}
