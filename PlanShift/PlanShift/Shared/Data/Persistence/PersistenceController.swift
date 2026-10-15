//
//  PersistenceController.swift
//  PlanShift
//
//  Created by Chang Chia ming on 2026/10/14.
//

import CoreData
import Foundation

@MainActor
final class PersistenceController {
    static let appGroupIdentifier =
        "group.com.utsstudent.zhaoziying.planshift"

    enum PersistenceError: Error {
        case modelNotFound
        case appGroupUnavailable
    }

    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    init(inMemory: Bool = false) throws {
        guard let modelURL = Bundle.main.url(
            forResource: "PlanShiftModel",
            withExtension: "momd"
        ),
        let model = NSManagedObjectModel(contentsOf: modelURL) else {
            throw PersistenceError.modelNotFound
        }

        container = NSPersistentContainer(
            name: "PlanShiftModel",
            managedObjectModel: model
        )

        let storeType: NSPersistentStore.StoreType
        let storeURL: URL
        let options: [AnyHashable: Any]

        if inMemory {
            storeType = .inMemory
            storeURL = URL(fileURLWithPath: "/dev/null")
            options = [:]
        } else {
            guard let groupURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier:
                    Self.appGroupIdentifier
            ) else {
                throw PersistenceError.appGroupUnavailable
            }

            storeType = .sqlite
            storeURL = groupURL.appendingPathComponent(
                "PlanShift.sqlite"
            )
            options = [
                NSMigratePersistentStoresAutomaticallyOption: true,
                NSInferMappingModelAutomaticallyOption: true
            ]
        }

        _ = try container.persistentStoreCoordinator.addPersistentStore(
            type: storeType,
            at: storeURL,
            options: options
        )

        viewContext.automaticallyMergesChangesFromParent = true
        viewContext.mergePolicy =
            NSMergeByPropertyObjectTrumpMergePolicy
    }

    func save() throws {
        guard viewContext.hasChanges else { return }
        try viewContext.save()
    }
}
