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
}
