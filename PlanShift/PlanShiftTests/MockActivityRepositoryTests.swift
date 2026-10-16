//
//  MockActivityRepositoryTests.swift
//  PlanShiftTests
//
//  Created by Chang Chia ming on 2026/10/15.
//

import Foundation
import XCTest
@testable import PlanShift

final class MockActivityRepositoryTests: XCTestCase {
    func testFetchReturnsEmptyWhenNoActivities() async throws {
        let repository = MockActivityRepository()

        let tripActivities = try await repository.fetchActivities(
            tripId: UUID()
        )
        let dayActivities = try await repository.fetchActivities(
            on: baseDate
        )

        XCTAssertTrue(tripActivities.isEmpty)
        XCTAssertTrue(dayActivities.isEmpty)
    }

    func testFetchByTripFiltersAndSortsActivities() async throws {
        let tripId = UUID()
        let earlier = makeActivity(tripId: tripId, hour: 9)
        let later = makeActivity(tripId: tripId, hour: 14)
        let otherTrip = makeActivity(hour: 8)
        let repository = MockActivityRepository(
            activities: [later, otherTrip, earlier]
        )

        let result = try await repository.fetchActivities(
            tripId: tripId
        )

        XCTAssertEqual(result, [earlier, later])
    }

    func testFetchByDayFiltersAndSortsActivities() async throws {
        let earlier = makeActivity(hour: 9)
        let later = makeActivity(hour: 14)
        let nextDay = try XCTUnwrap(
            Calendar.current.date(
                byAdding: .day,
                value: 1,
                to: baseDate
            )
        )
        let otherDay = makeActivity(day: nextDay, hour: 8)
        let repository = MockActivityRepository(
            activities: [later, otherDay, earlier]
        )
        let queryDate = baseDate.addingTimeInterval(12 * 3_600)

        let result = try await repository.fetchActivities(
            on: queryDate
        )

        XCTAssertEqual(result, [earlier, later])
    }

    func testAddPreservesExistingActivities() async throws {
        let tripId = UUID()
        let existing = makeActivity(tripId: tripId, hour: 9)
        let added = makeActivity(tripId: tripId, hour: 14)
        let repository = MockActivityRepository(
            activities: [existing]
        )

        try await repository.add(added)
        let result = try await repository.fetchActivities(
            tripId: tripId
        )

        XCTAssertEqual(result, [existing, added])
    }

    func testUpdateChangesOnlyMatchingActivity() async throws {
        let tripId = UUID()
        let original = makeActivity(tripId: tripId, hour: 9)
        let other = makeActivity(tripId: tripId, hour: 14)
        let repository = MockActivityRepository(
            activities: [original, other]
        )
        var updated = original
        updated.name = "Updated Museum"
        updated.estimatedCost = 25

        try await repository.update(updated)
        let result = try await repository.fetchActivities(
            tripId: tripId
        )

        XCTAssertEqual(result, [updated, other])
    }

    func testUpdateMissingActivityThrowsAndPreservesData() async throws {
        let existing = makeActivity()
        let repository = MockActivityRepository(
            activities: [existing]
        )

        do {
            try await repository.update(makeActivity())
            XCTFail("Expected activityNotFound.")
        } catch {
            XCTAssertEqual(error as? DomainError, .activityNotFound)
        }

        let result = try await repository.fetchActivities(
            tripId: existing.tripId
        )
        XCTAssertEqual(result, [existing])
    }

    func testDeleteRemovesOnlyMatchingActivity() async throws {
        let tripId = UUID()
        let removed = makeActivity(tripId: tripId, hour: 9)
        let kept = makeActivity(tripId: tripId, hour: 14)
        let repository = MockActivityRepository(
            activities: [removed, kept]
        )

        try await repository.delete(id: removed.id)
        let result = try await repository.fetchActivities(
            tripId: tripId
        )

        XCTAssertEqual(result, [kept])
    }

    func testDeleteMissingActivityThrowsAndPreservesData() async throws {
        let existing = makeActivity()
        let repository = MockActivityRepository(
            activities: [existing]
        )

        do {
            try await repository.delete(id: UUID())
            XCTFail("Expected activityNotFound.")
        } catch {
            XCTAssertEqual(error as? DomainError, .activityNotFound)
        }

        let result = try await repository.fetchActivities(
            tripId: existing.tripId
        )
        XCTAssertEqual(result, [existing])
    }

    func testNextUpcomingReturnsEarliestStrictlyLaterActivity() async throws {
        let past = makeActivity(hour: 8)
        let atBoundary = makeActivity(hour: 9)
        let next = makeActivity(hour: 10)
        let later = makeActivity(hour: 14)
        let repository = MockActivityRepository(
            activities: [later, atBoundary, next, past]
        )

        let result = try await repository.fetchNextUpcoming(
            after: atBoundary.startTime
        )

        XCTAssertEqual(result, next)
    }

    func testNextUpcomingReturnsNilWhenNoneRemain() async throws {
        let activity = makeActivity(hour: 9)
        let repository = MockActivityRepository(
            activities: [activity]
        )

        let result = try await repository.fetchNextUpcoming(
            after: activity.endTime
        )

        XCTAssertNil(result)
    }

    private var baseDate: Date {
        Calendar.current.startOfDay(
            for: Date(timeIntervalSince1970: 1_800_000_000)
        )
    }

    private func makeActivity(
        tripId: UUID = UUID(),
        day: Date? = nil,
        hour: Int = 9
    ) -> ItineraryActivity {
        let activityDate = day ?? baseDate
        let startTime = activityDate.addingTimeInterval(
            TimeInterval(hour * 3_600)
        )

        return ItineraryActivity(
            tripId: tripId,
            name: "Museum",
            date: activityDate,
            startTime: startTime,
            endTime: startTime.addingTimeInterval(3_600),
            locationName: "Sydney",
            latitude: -33.8688,
            longitude: 151.2093,
            setting: .indoor,
            estimatedCost: 0
        )
    }
}
