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
    func testReplaceUpdatesPlaceDetailsAndDuration() async throws {
        let original = makeActivity()
        let place = makePlace()
        let repository = MockActivityRepository(
            activities: [original]
        )
        let useCase = ReplaceActivityUseCase(
            activityRepository: repository,
            backupRepository: MockBackupRepository()
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
        XCTAssertEqual(
            updated.endTime,
            original.startTime.addingTimeInterval(
                TimeInterval(place.durationMinutes) * 60
            )
        )
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
            activityRepository: repository,
            backupRepository: MockBackupRepository()
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
            activityRepository: repository,
            backupRepository: MockBackupRepository()
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
        XCTAssertEqual(
            updated.endTime,
            stored.startTime.addingTimeInterval(3_600)
        )
    }

    func testReplaceMissingActivityThrowsAndPreservesOtherActivity() async throws {
        let existing = makeActivity()
        var missing = makeActivity()
        missing.tripId = existing.tripId

        let repository = MockActivityRepository(
            activities: [existing]
        )
        let useCase = ReplaceActivityUseCase(
            activityRepository: repository,
            backupRepository: MockBackupRepository()
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
    
    func testReplaceRejectsNonPositiveDuration() async throws {
        for duration in [0, -1] {
            let original = makeActivity()
            var place = makePlace()
            place.durationMinutes = duration

            let repository = MockActivityRepository(
                activities: [original]
            )
            let useCase = ReplaceActivityUseCase(
                activityRepository: repository,
                backupRepository: MockBackupRepository()
            )

            do {
                _ = try await useCase.execute(
                    activity: original,
                    with: place
                )
                XCTFail("Expected invalidTimeRange.")
            } catch {
                XCTAssertEqual(error as? DomainError, .invalidTimeRange)
            }

            let result = try await repository.fetchActivities(
                tripId: original.tripId
            )
            XCTAssertEqual(result, [original])
        }
    }

    func testReplaceRejectsTimeConflictAndPreservesData() async throws {
        let original = makeActivity()
        var other = makeActivity()
        other.tripId = original.tripId
        other.startTime = original.endTime
        other.endTime = other.startTime.addingTimeInterval(3_600)

        var place = makePlace()
        place.durationMinutes = 180

        let repository = MockActivityRepository(
            activities: [original, other]
        )
        let useCase = ReplaceActivityUseCase(
            activityRepository: repository,
            backupRepository: MockBackupRepository()
        )

        do {
            _ = try await useCase.execute(
                activity: original,
                with: place
            )
            XCTFail("Expected timeConflict.")
        } catch {
            XCTAssertEqual(error as? DomainError, .timeConflict)
        }

        let result = try await repository.fetchActivities(
            tripId: original.tripId
        )
        XCTAssertEqual(result, [original, other])
    }

    func testReplaceAllowsAdjacentActivities() async throws {
        let original = makeActivity()

        var previous = makeActivity()
        previous.tripId = original.tripId
        previous.startTime = original.startTime.addingTimeInterval(-3_600)
        previous.endTime = original.startTime

        var next = makeActivity()
        next.tripId = original.tripId
        next.startTime = original.startTime.addingTimeInterval(3_600)
        next.endTime = next.startTime.addingTimeInterval(3_600)

        let repository = MockActivityRepository(
            activities: [previous, original, next]
        )
        let useCase = ReplaceActivityUseCase(
            activityRepository: repository,
            backupRepository: MockBackupRepository()
        )
        let place = makePlace()

        _ = try await useCase.execute(
            activity: original,
            with: place
        )

        var expected = original
        expected.name = place.name
        expected.locationName = place.name
        expected.latitude = place.latitude
        expected.longitude = place.longitude
        expected.setting = place.setting
        expected.estimatedCost = place.cost
        expected.endTime = next.startTime

        let result = try await repository.fetchActivities(
            tripId: original.tripId
        )
        XCTAssertEqual(result, [previous, expected, next])
    }

    func testRestoreOriginalPlanKeepsItsNameLocationAndLength() async throws {
        let replacement = makeActivity()
        let originalPlan = ItineraryActivity(
            id: replacement.id,
            tripId: replacement.tripId,
            name: "Botanic Garden stroll",
            date: replacement.date,
            startTime: replacement.startTime,
            endTime: replacement.startTime.addingTimeInterval(5_400),
            locationName: "Royal Botanic Garden Sydney",
            latitude: -33.8628,
            longitude: 151.2157,
            setting: .outdoor,
            estimatedCost: 0
        )

        let repository = MockActivityRepository(
            activities: [replacement]
        )
        let backups = MockBackupRepository()
        let useCase = ReplaceActivityUseCase(
            activityRepository: repository,
            backupRepository: backups
        )

        let result = try await useCase.execute(
            activity: replacement,
            restoring: originalPlan
        )

        let activities = try await repository.fetchActivities(
            tripId: replacement.tripId
        )
        let updated = try XCTUnwrap(activities.first)
        XCTAssertEqual(result, replacement)
        XCTAssertEqual(updated.id, replacement.id)
        XCTAssertEqual(updated.name, "Botanic Garden stroll")
        XCTAssertEqual(updated.locationName, "Royal Botanic Garden Sydney")
        XCTAssertEqual(updated.startTime, replacement.startTime)
        XCTAssertEqual(updated.endTime, replacement.startTime.addingTimeInterval(5_400))
        XCTAssertEqual(updated.estimatedCost, 0)

        let saved = try await backups.fetchBackups(tripId: replacement.tripId)
        XCTAssertEqual(saved.map(\.content), [.activity(replacement)])
    }

    func testRestoreOriginalPlanRejectsTimeConflictAndPreservesData() async throws {
        let replacement = makeActivity()
        var next = makeActivity()
        next.tripId = replacement.tripId
        next.startTime = replacement.endTime
        next.endTime = next.startTime.addingTimeInterval(3_600)

        var originalPlan = makeActivity()
        originalPlan.tripId = replacement.tripId
        originalPlan.endTime = originalPlan.startTime.addingTimeInterval(10_800)

        let repository = MockActivityRepository(
            activities: [replacement, next]
        )
        let backups = MockBackupRepository()
        let useCase = ReplaceActivityUseCase(
            activityRepository: repository,
            backupRepository: backups
        )

        do {
            _ = try await useCase.execute(
                activity: replacement,
                restoring: originalPlan
            )
            XCTFail("Expected timeConflict.")
        } catch {
            XCTAssertEqual(error as? DomainError, .timeConflict)
        }

        let result = try await repository.fetchActivities(
            tripId: replacement.tripId
        )
        XCTAssertEqual(result, [replacement, next])
        let saved = try await backups.fetchBackups(tripId: replacement.tripId)
        XCTAssertTrue(saved.isEmpty)
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
