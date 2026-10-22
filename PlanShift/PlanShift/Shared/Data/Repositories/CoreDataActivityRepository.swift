//
//  CoreDataActivityRepository.swift
//  PlanShift
//
//  Created by Tianqi Li's Macbook pro on 21/10/2026.
//


import CoreData
import Foundation

// Module: M1 - Core Data Activity Repository

@MainActor
final class CoreDataActivityRepository: ActivityRepository {

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
    func fetchActivities(
        tripId: UUID
    ) async throws -> [ItineraryActivity] {
        let request = NSFetchRequest<ActivityEntity>(
            entityName: "ActivityEntity"
        )

        request.predicate = NSPredicate(
            format: "tripId == %@",
            tripId as CVarArg
        )

        request.sortDescriptors = [
            NSSortDescriptor(key: "startTime", ascending: true)
        ]

        return try context.fetch(request).map { try toActivity($0) }
    }

    @MainActor
    func fetchActivities(
        on date: Date
    ) async throws -> [ItineraryActivity] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)

        guard let end = calendar.date(
            byAdding: .day,
            value: 1,
            to: start
        ) else {
            return []
        }

        let request = NSFetchRequest<ActivityEntity>(
            entityName: "ActivityEntity"
        )

        request.predicate = NSPredicate(
            format: "date >= %@ AND date < %@",
            start as NSDate,
            end as NSDate
        )

        request.sortDescriptors = [
            NSSortDescriptor(key: "startTime", ascending: true)
        ]

        return try context.fetch(request).map { try toActivity($0) }
    }

    @MainActor
    func add(
        _ activity: ItineraryActivity
    ) async throws {
        let request = NSFetchRequest<ActivityEntity>(
            entityName: "ActivityEntity"
        )

        request.predicate = NSPredicate(
            format: "id == %@",
            activity.id as CVarArg
        )

        request.fetchLimit = 1

        guard try context.fetch(request).isEmpty else {
            throw M1ActivityPersistenceError.activityAlreadyExists
        }

        let entity = ActivityEntity(context: context)
        apply(activity, to: entity)

        try saveChanges()
    }

    @MainActor
    func update(
        _ activity: ItineraryActivity
    ) async throws {
        guard let entity = try fetchEntity(id: activity.id) else {
            throw DomainError.activityNotFound
        }

        apply(activity, to: entity)
        try saveChanges()
    }

    @MainActor
    func delete(id: UUID) async throws {
        guard let entity = try fetchEntity(id: id) else {
            throw DomainError.activityNotFound
        }

        context.delete(entity)
        try saveChanges()
    }

    @MainActor
    func fetchNextUpcoming(
        after date: Date
    ) async throws -> ItineraryActivity? {
        let request = NSFetchRequest<ActivityEntity>(
            entityName: "ActivityEntity"
        )

        request.predicate = NSPredicate(
            format: "startTime > %@",
            date as NSDate
        )

        request.sortDescriptors = [
            NSSortDescriptor(key: "startTime", ascending: true)
        ]

        request.fetchLimit = 1

        guard let entity = try context.fetch(request).first else {
            return nil
        }

        return try toActivity(entity)
    }

    private func fetchEntity(
        id: UUID
    ) throws -> ActivityEntity? {
        let request = NSFetchRequest<ActivityEntity>(
            entityName: "ActivityEntity"
        )

        request.predicate = NSPredicate(
            format: "id == %@",
            id as CVarArg
        )

        request.fetchLimit = 1

        return try context.fetch(request).first
    }

    private func apply(
        _ activity: ItineraryActivity,
        to entity: ActivityEntity
    ) {
        entity.id = activity.id
        entity.tripId = activity.tripId
        entity.name = activity.name
        entity.date = activity.date
        entity.startTime = activity.startTime
        entity.endTime = activity.endTime
        entity.locationName = activity.locationName
        entity.latitude = activity.latitude
        entity.longitude = activity.longitude
        entity.setting = activity.setting.title.lowercased()
        entity.estimatedCost = activity.estimatedCost as NSDecimalNumber
    }

    private func toActivity(
        _ entity: ActivityEntity
    ) throws -> ItineraryActivity {
        guard let id = entity.id,
              let tripId = entity.tripId,
              let name = entity.name,
              let date = entity.date,
              let startTime = entity.startTime,
              let endTime = entity.endTime,
              let locationName = entity.locationName,
              let settingName = entity.setting,
              let cost = entity.estimatedCost else {
            throw M1ActivityPersistenceError.invalidStoredActivity
        }

        let setting: ActivitySetting

        switch settingName.lowercased() {
        case "indoor":
            setting = .indoor
        case "outdoor":
            setting = .outdoor
        default:
            throw M1ActivityPersistenceError.invalidStoredActivity
        }

        return ItineraryActivity(
            id: id,
            tripId: tripId,
            name: name,
            date: date,
            startTime: startTime,
            endTime: endTime,
            locationName: locationName,
            latitude: entity.latitude,
            longitude: entity.longitude,
            setting: setting,
            estimatedCost: cost.decimalValue
        )
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

nonisolated enum M1ActivityPersistenceError: LocalizedError {
    case activityAlreadyExists
    case invalidStoredActivity

    var errorDescription: String? {
        switch self {
        case .activityAlreadyExists:
            return "This activity already exists."
        case .invalidStoredActivity:
            return "The saved activity contains incomplete data."
        }
    }
}
