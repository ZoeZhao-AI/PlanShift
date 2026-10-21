//
//  PersistenceControllerTests.swift
//  PlanShiftTests
//
//  Created by Chang Chia ming on 2026/10/14.
//

import CoreData
import XCTest
@testable import PlanShift

final class PersistenceControllerTests: XCTestCase {
    @MainActor
    func testInMemoryStoreLoads() throws {
        let persistence = try PersistenceController(inMemory: true)
        let stores = persistence.container
            .persistentStoreCoordinator.persistentStores

        XCTAssertEqual(stores.count, 1)

        let store = try XCTUnwrap(stores.first)
        XCTAssertEqual(store.type, NSInMemoryStoreType)
        XCTAssertTrue(
            persistence.viewContext.persistentStoreCoordinator ===
                persistence.container.persistentStoreCoordinator
        )
    }
    
    @MainActor
    func testSQLiteStoreLoadsInAppGroup() throws {
        let groupURL = try XCTUnwrap(
            FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier:
                    PersistenceController.appGroupIdentifier
            )
        )

        let persistence = try PersistenceController()
        let stores = persistence.container
            .persistentStoreCoordinator.persistentStores

        XCTAssertEqual(stores.count, 1)

        let store = try XCTUnwrap(stores.first)
        let storeURL = try XCTUnwrap(store.url)
        let expectedURL = groupURL.appendingPathComponent("PlanShift.sqlite")

        XCTAssertEqual(store.type, NSSQLiteStoreType)
        XCTAssertEqual(
            storeURL.standardizedFileURL,
            expectedURL.standardizedFileURL
        )
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: storeURL.path)
        )
    }
    
    @MainActor
    func testControllersShareManagedObjectModel() throws {
        let first = try PersistenceController(inMemory: true)
        let second = try PersistenceController(inMemory: true)

        XCTAssertTrue(
            first.container.managedObjectModel ===
            second.container.managedObjectModel
        )

        XCTAssertFalse(first.container === second.container)
        XCTAssertFalse(first.viewContext === second.viewContext)
    }
}
