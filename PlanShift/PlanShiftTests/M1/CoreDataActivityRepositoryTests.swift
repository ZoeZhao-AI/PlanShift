//
//  CoreDataActivityRepositoryTests.swift
//  PlanShiftTests
//
//  Created by Tianqi Li's Macbook pro on 21/10/2026.
//

import CoreData
import Foundation
import XCTest
@testable import PlanShift

final class CoreDataActivityRepositoryTests: XCTestCase {

    @MainActor
    private func makeActivity(
        id: UUID = UUID(),
        tripId: UUID = UUID(),
        name: String = "Taronga Zoo",
        startTime: Date = Date()
    ) -> ItineraryActivity {

        let endTime = startTime.addingTimeInterval(3600)

        return ItineraryActivity(
            id: id,
            tripId: tripId,
            name: name,
            date: Calendar.current.startOfDay(for: startTime),
            startTime: startTime,
            endTime: endTime,
            locationName: "Sydney",
            latitude: -33.843,
            longitude: 151.241,
            setting: .outdoor,
            estimatedCost: Decimal(45)
        )
    }

    @MainActor
    func testAddAndFetchActivity() async throws {
        let persistence = try PersistenceController(inMemory: true)

        let repository = CoreDataActivityRepository(
            container: persistence.container
        )

        let tripId = UUID()
        let activity = makeActivity(tripId: tripId)

        try await repository.add(activity)

        let saved = try await repository.fetchActivities(
            tripId: tripId
        )

        XCTAssertEqual(saved.count, 1)
        XCTAssertEqual(saved.first?.id, activity.id)
        XCTAssertEqual(saved.first?.name, "Taronga Zoo")
        XCTAssertEqual(saved.first?.tripId, tripId)
        XCTAssertEqual(saved.first?.setting, .outdoor)
        XCTAssertEqual(saved.first?.estimatedCost, Decimal(45))
    }

    @MainActor
    func testUpdateActivity() async throws {
        let persistence = try PersistenceController(inMemory: true)

        let repository = CoreDataActivityRepository(
            container: persistence.container
        )

        var activity = makeActivity()

        try await repository.add(activity)

        activity.name = "Updated Zoo Visit"
        activity.estimatedCost = Decimal(60)

        try await repository.update(activity)

        let saved = try await repository.fetchActivities(
            tripId: activity.tripId
        )

        XCTAssertEqual(saved.count, 1)
        XCTAssertEqual(saved.first?.name, "Updated Zoo Visit")
        XCTAssertEqual(saved.first?.estimatedCost, Decimal(60))
    }

    @MainActor
    func testDeleteActivity() async throws {
        let persistence = try PersistenceController(inMemory: true)

        let repository = CoreDataActivityRepository(
            container: persistence.container
        )

        let activity = makeActivity()

        try await repository.add(activity)
        try await repository.delete(id: activity.id)

        let saved = try await repository.fetchActivities(
            tripId: activity.tripId
        )

        XCTAssertTrue(saved.isEmpty)
    }

    @MainActor
    func testFetchActivitiesByDate() async throws {
        let persistence = try PersistenceController(inMemory: true)

        let repository = CoreDataActivityRepository(
            container: persistence.container
        )

        let tripId = UUID()
        let today = Date()
        let tomorrow = Calendar.current.date(
            byAdding: .day,
            value: 1,
            to: today
        )!

        let first = makeActivity(
            tripId: tripId,
            name: "Morning Activity",
            startTime: today
        )

        let second = makeActivity(
            tripId: tripId,
            name: "Tomorrow Activity",
            startTime: tomorrow
        )

        try await repository.add(first)
        try await repository.add(second)

        let saved = try await repository.fetchActivities(
            on: today
        )

        XCTAssertEqual(saved.count, 1)
        XCTAssertEqual(saved.first?.id, first.id)
    }

    @MainActor
    func testFetchNextUpcoming() async throws {
        let persistence = try PersistenceController(inMemory: true)

        let repository = CoreDataActivityRepository(
            container: persistence.container
        )

        let now = Date()

        let first = makeActivity(
            name: "First Activity",
            startTime: now.addingTimeInterval(3600)
        )

        let second = makeActivity(
            name: "Second Activity",
            startTime: now.addingTimeInterval(7200)
        )

        try await repository.add(second)
        try await repository.add(first)

        let upcoming = try await repository.fetchNextUpcoming(
            after: now
        )

        XCTAssertEqual(upcoming?.id, first.id)
    }
}
