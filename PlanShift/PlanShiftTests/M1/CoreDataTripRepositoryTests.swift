//
//  CoreDataTripRepositoryTests.swift
//  PlanShiftTests
//
//  Created by Tianqi Li's Macbook pro on 21/10/2026.
//

import CoreData
import XCTest
@testable import PlanShift

final class CoreDataTripRepositoryTests: XCTestCase {

    @MainActor
    func testCreateAndFetchTrip() async throws {
        let persistence = try PersistenceController(inMemory: true)

        let repository = CoreDataTripRepository(
            container: persistence.container
        )

        let startDate = Date()
        let endDate = Calendar.current.date(
            byAdding: .day,
            value: 2,
            to: startDate
        )!

        let trip = Trip(
            name: "Sydney Weekend",
            startDate: startDate,
            endDate: endDate
        )

        try await repository.createTrip(trip)

        let savedTrip = try await repository.fetchCurrentTrip()

        XCTAssertNotNil(savedTrip)
        XCTAssertEqual(savedTrip?.id, trip.id)
        XCTAssertEqual(savedTrip?.name, "Sydney Weekend")
        XCTAssertEqual(savedTrip?.startDate, startDate)
        XCTAssertEqual(savedTrip?.endDate, endDate)
    }

    @MainActor
    func testUpdateTrip() async throws {
        let persistence = try PersistenceController(inMemory: true)

        let repository = CoreDataTripRepository(
            container: persistence.container
        )

        let startDate = Date()
        let endDate = Calendar.current.date(
            byAdding: .day,
            value: 2,
            to: startDate
        )!

        var trip = Trip(
            name: "Sydney Weekend",
            startDate: startDate,
            endDate: endDate
        )

        try await repository.createTrip(trip)

        trip.name = "Updated Sydney Trip"

        try await repository.updateTrip(trip)

        let savedTrip = try await repository.fetchCurrentTrip()

        XCTAssertEqual(savedTrip?.id, trip.id)
        XCTAssertEqual(savedTrip?.name, "Updated Sydney Trip")
    }
    
    
    @MainActor
    func testTripPersistsAfterReopeningStore() async throws {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)

        try FileManager.default.createDirectory(
            at: folder,
            withIntermediateDirectories: true
        )

        defer {
            try? FileManager.default.removeItem(at: folder)
        }

        let storeURL = folder.appendingPathComponent("M1Test.sqlite")

        let model = try XCTUnwrap(
            PersistenceController(inMemory: true)
                .container.managedObjectModel
                .copy() as? NSManagedObjectModel
        )

        func makeContainer() throws -> NSPersistentContainer {
            let container = NSPersistentContainer(
                name: "PlanShiftModel",
                managedObjectModel: model
            )

            let description = NSPersistentStoreDescription(
                url: storeURL
            )
            description.type = NSSQLiteStoreType
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true

            container.persistentStoreDescriptions = [description]

            var loadError: Error?

            container.loadPersistentStores { _, error in
                loadError = error
            }

            if let loadError {
                throw loadError
            }

            return container
        }

        let trip = Trip(
            name: "Persistent Sydney Trip",
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400)
        )

        // First connection: save the trip.
        do {
            let container = try makeContainer()
            let repository = CoreDataTripRepository(
                container: container
            )

            try await repository.createTrip(trip)
        }

        // Second connection: reopen the same SQLite file.
        do {
            let container = try makeContainer()
            let repository = CoreDataTripRepository(
                container: container
            )

            let savedTrip = try await repository.fetchCurrentTrip()

            XCTAssertEqual(savedTrip?.id, trip.id)
            XCTAssertEqual(savedTrip?.name, trip.name)
        }
    }

}

