//
//  ReplaceActivityUseCaseTests.swift
//  PlanShiftTests
//
//  Created by Chang Chia ming on 2026/10/15.
//

import Foundation
import XCTest
@testable import PlanShift

final class ReplaceActivityUseCaseTests: XCTestCase {
    func testReplaceUpdatesPlaceDetailsAndPreservesSchedule() async throws {
        let original = makeActivity()
        let place = makePlace()
        let repository = MockActivityRepository(
            activities: [original]
        )
        let useCase = ReplaceActivityUseCase(
            activityRepository: repository
        )

        _ = try await useCase.execute(
            activity: original,
            with: place
        )

        let activities = try await repository.fetchActivities(
            tripId: original.tripId
        )
        let updated = try XCTUnwrap(activities.first)

        XCTAssertEqual(activities.count, 1)
        XCTAssertEqual(updated.id, original.id)
        XCTAssertEqual(updated.tripId, original.tripId)
        XCTAssertEqual(updated.date, original.date)
        XCTAssertEqual(updated.startTime, original.startTime)
        XCTAssertEqual(updated.endTime, original.endTime)
        XCTAssertEqual(updated.name, place.name)
        XCTAssertEqual(updated.locationName, place.name)
        XCTAssertEqual(updated.latitude, place.latitude)
        XCTAssertEqual(updated.longitude, place.longitude)
        XCTAssertEqual(updated.setting, place.setting)
        XCTAssertEqual(updated.estimatedCost, place.cost)
    }

    func testReplaceReturnsOriginalActivityForUndo() async throws {
        let original = makeActivity()
        let repository = MockActivityRepository(
            activities: [original]
        )
        let useCase = ReplaceActivityUseCase(
            activityRepository: repository
        )

        let result = try await useCase.execute(
            activity: original,
            with: makePlace()
        )

        XCTAssertEqual(result, original)
    }

    func testReplaceUsesStoredActivityInsteadOfOutdatedInput() async throws {
        let outdated = makeActivity()
        var stored = outdated
        stored.name = "Updated Original Activity"
        stored.startTime = outdated.startTime.addingTimeInterval(600)
        stored.endTime = outdated.endTime.addingTimeInterval(600)

        let repository = MockActivityRepository(
            activities: [stored]
        )
        let useCase = ReplaceActivityUseCase(
            activityRepository: repository
        )

        let result = try await useCase.execute(
            activity: outdated,
            with: makePlace()
        )
        let activities = try await repository.fetchActivities(
            tripId: stored.tripId
        )
        let updated = try XCTUnwrap(activities.first)

        XCTAssertEqual(result, stored)
        XCTAssertEqual(updated.startTime, stored.startTime)
        XCTAssertEqual(updated.endTime, stored.endTime)
    }

    func testReplaceMissingActivityThrowsAndPreservesOtherActivity() async throws {
        let existing = makeActivity()
        var missing = makeActivity()
        missing.tripId = existing.tripId

        let repository = MockActivityRepository(
            activities: [existing]
        )
        let useCase = ReplaceActivityUseCase(
            activityRepository: repository
        )

        do {
            _ = try await useCase.execute(
                activity: missing,
                with: makePlace()
            )
            XCTFail("Expected activityNotFound.")
        } catch {
            XCTAssertEqual(error as? DomainError, .activityNotFound)
        }

        let activities = try await repository.fetchActivities(
            tripId: existing.tripId
        )

        XCTAssertEqual(activities, [existing])
    }

    private func makeActivity() -> ItineraryActivity {
        let startTime = Date(
            timeIntervalSince1970: 1_800_000_000
        )

        return ItineraryActivity(
            tripId: UUID(),
            name: "Original Park",
            date: Calendar.current.startOfDay(for: startTime),
            startTime: startTime,
            endTime: startTime.addingTimeInterval(7_200),
            locationName: "Original Park",
            latitude: -33.8642,
            longitude: 151.2166,
            setting: .outdoor,
            estimatedCost: 10
        )
    }

    private func makePlace() -> Place {
        Place(
            name: "Alternative Museum",
            suburb: "Sydney",
            setting: .indoor,
            cost: 25,
            durationMinutes: 60,
            latitude: -33.8749,
            longitude: 151.2133,
            openingHour: 9,
            closingHour: 17,
            imageName: "",
            suitableDisruptions: []
        )
    }
}
