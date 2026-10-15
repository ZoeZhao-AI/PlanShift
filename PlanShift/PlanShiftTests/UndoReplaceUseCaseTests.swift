//
//  UndoReplaceUseCaseTests.swift
//  PlanShiftTests
//
//  Created by Chang Chia ming on 2026/10/15.
//

import Foundation
import XCTest
@testable import PlanShift

final class UndoReplaceUseCaseTests: XCTestCase {
    func testUndoRestoresActivityAfterReplace() async throws {
        let original = makeActivity()
        let repository = MockActivityRepository(
            activities: [original]
        )
        let replace = ReplaceActivityUseCase(
            activityRepository: repository,
            backupRepository: MockBackupRepository()
        )
        let undo = UndoReplaceUseCase(
            activityRepository: repository
        )

        let savedOriginal = try await replace.execute(
            activity: original,
            with: makePlace()
        )

        try await undo.execute(originalActivity: savedOriginal)

        let result = try await repository.fetchActivities(
            tripId: original.tripId
        )

        XCTAssertEqual(result, [original])
    }

    func testUndoPreservesOtherActivities() async throws {
        let original = makeActivity()
        var other = makeActivity()
        other.tripId = original.tripId
        other.startTime = original.endTime
        other.endTime = other.startTime.addingTimeInterval(3_600)

        let repository = MockActivityRepository(
            activities: [original, other]
        )
        let replace = ReplaceActivityUseCase(
            activityRepository: repository,
            backupRepository: MockBackupRepository()
        )
        let undo = UndoReplaceUseCase(
            activityRepository: repository
        )

        let savedOriginal = try await replace.execute(
            activity: original,
            with: makePlace()
        )

        try await undo.execute(originalActivity: savedOriginal)

        let result = try await repository.fetchActivities(
            tripId: original.tripId
        )

        XCTAssertEqual(result, [original, other])
    }

    func testUndoDeletedActivityThrowsWithoutRecreatingIt() async throws {
        let original = makeActivity()
        let repository = MockActivityRepository(
            activities: [original]
        )
        let replace = ReplaceActivityUseCase(
            activityRepository: repository,
            backupRepository: MockBackupRepository()
        )
        let undo = UndoReplaceUseCase(
            activityRepository: repository
        )

        let savedOriginal = try await replace.execute(
            activity: original,
            with: makePlace()
        )
        try await repository.delete(id: original.id)

        do {
            try await undo.execute(originalActivity: savedOriginal)
            XCTFail("Expected activityNotFound.")
        } catch {
            XCTAssertEqual(error as? DomainError, .activityNotFound)
        }

        let result = try await repository.fetchActivities(
            tripId: original.tripId
        )

        XCTAssertTrue(result.isEmpty)
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
