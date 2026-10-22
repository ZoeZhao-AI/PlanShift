//
//  M1CoreDataModelTests.swift
//  PlanShiftTests
//
//  Created by Tianqi Li's Macbook pro on 21/10/2026.
//

import CoreData
import XCTest
@testable import PlanShift

final class M1CoreDataModelTests: XCTestCase {

    @MainActor
    func testSharedModelContainsM1Entities() throws {
        // Use the team's controller with a temporary test store.
        let persistence = try PersistenceController(inMemory: true)

        let entities = persistence.container
            .managedObjectModel.entitiesByName

        // Keep the existing shared entity.
        XCTAssertNotNil(
            entities["BackupEntity"],
            "BackupEntity is missing from the loaded model."
        )

        // Check that the new M1 entities are actually loaded.
        XCTAssertNotNil(
            entities["TripEntity"],
            "TripEntity is missing. Check the current model version."
        )

        XCTAssertNotNil(
            entities["ActivityEntity"],
            "ActivityEntity is missing. Check the current model version."
        )
    }
}
