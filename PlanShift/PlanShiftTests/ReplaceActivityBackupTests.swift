//
//  ReplaceActivityBackupTests.swift
//  PlanShiftTests
//
//  Created by Chang Chia ming on 2026/10/16.
//

import Foundation
import XCTest
@testable import PlanShift

final class ReplaceActivityBackupTests: XCTestCase {
    @MainActor
    func testReplaceSavesOriginalActivityAsBackup() async throws {
        let original = PreviewSamples.coastalWalk
        let activities = MockActivityRepository(
            activities: [original]
        )
        let backups = MockBackupRepository()
        let useCase = ReplaceActivityUseCase(
            activityRepository: activities,
            backupRepository: backups
        )

        _ = try await useCase.execute(
            activity: original,
            with: PreviewSamples.australianMuseum
        )

        let result = try await backups.fetchBackups(
            tripId: original.tripId
        )
        let backup = try XCTUnwrap(result.first)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(backup.tripId, original.tripId)
        XCTAssertEqual(backup.dayDate, original.date)
        XCTAssertEqual(backup.content, .activity(original))
    }

    @MainActor
    func testBackupFailureLeavesActivityUnchanged() async throws {
        let original = PreviewSamples.coastalWalk
        let activities = MockActivityRepository(
            activities: [original]
        )
        let backups = MockBackupRepository(
            saveError: .persistenceFailure
        )
        let useCase = ReplaceActivityUseCase(
            activityRepository: activities,
            backupRepository: backups
        )

        do {
            _ = try await useCase.execute(
                activity: original,
                with: PreviewSamples.australianMuseum
            )
            XCTFail("Expected persistenceFailure.")
        } catch {
            XCTAssertEqual(error as? DomainError, .persistenceFailure)
        }

        let storedActivities = try await activities.fetchActivities(
            tripId: original.tripId
        )
        let storedBackups = try await backups.fetchBackups(
            tripId: original.tripId
        )

        XCTAssertEqual(storedActivities, [original])
        XCTAssertTrue(storedBackups.isEmpty)
    }

    @MainActor
    func testUpdateFailureRemovesOnlyNewBackup() async throws {
        let original = PreviewSamples.coastalWalk
        let existingBackup = BackupOption(
            tripId: original.tripId,
            content: .place(PreviewSamples.australianMuseum),
            dayDate: original.date
        )
        let activities = MockActivityRepository(
            activities: [original],
            updateError: .persistenceFailure
        )
        let backups = MockBackupRepository(
            backups: [existingBackup]
        )
        let useCase = ReplaceActivityUseCase(
            activityRepository: activities,
            backupRepository: backups
        )

        do {
            _ = try await useCase.execute(
                activity: original,
                with: PreviewSamples.australianMuseum
            )
            XCTFail("Expected persistenceFailure.")
        } catch {
            XCTAssertEqual(error as? DomainError, .persistenceFailure)
        }

        let storedActivities = try await activities.fetchActivities(
            tripId: original.tripId
        )
        let storedBackups = try await backups.fetchBackups(
            tripId: original.tripId
        )

        XCTAssertEqual(storedActivities, [original])
        XCTAssertEqual(storedBackups, [existingBackup])
    }

    @MainActor
    func testCleanupFailureReportsBothErrors() async throws {
        let original = PreviewSamples.coastalWalk
        let activities = MockActivityRepository(
            activities: [original],
            updateError: .persistenceFailure
        )
        let backups = MockBackupRepository(
            deleteError: .persistenceFailure
        )
        let useCase = ReplaceActivityUseCase(
            activityRepository: activities,
            backupRepository: backups
        )

        do {
            _ = try await useCase.execute(
                activity: original,
                with: PreviewSamples.australianMuseum
            )
            XCTFail("Expected replacementCleanupFailed.")
        } catch {
            let domainError = try XCTUnwrap(error as? DomainError)

            guard case .replacementCleanupFailed(
                let updateFailure,
                let cleanupFailure
            ) = domainError else {
                XCTFail("Expected replacementCleanupFailed.")
                return
            }

            XCTAssertFalse(updateFailure.isEmpty)
            XCTAssertFalse(cleanupFailure.isEmpty)
        }

        let storedActivities = try await activities.fetchActivities(
            tripId: original.tripId
        )
        let storedBackups = try await backups.fetchBackups(
            tripId: original.tripId
        )

        XCTAssertEqual(storedActivities, [original])
        XCTAssertEqual(storedBackups.count, 1)
        XCTAssertEqual(
            storedBackups.first?.content,
            .activity(original)
        )
    }

    @MainActor
    func testInvalidDurationDoesNotCreateBackup() async throws {
        let original = PreviewSamples.coastalWalk
        var place = PreviewSamples.australianMuseum
        place.durationMinutes = 0

        let activities = MockActivityRepository(
            activities: [original]
        )
        let backups = MockBackupRepository()
        let useCase = ReplaceActivityUseCase(
            activityRepository: activities,
            backupRepository: backups
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

        let storedActivities = try await activities.fetchActivities(
            tripId: original.tripId
        )
        let storedBackups = try await backups.fetchBackups(
            tripId: original.tripId
        )

        XCTAssertEqual(storedActivities, [original])
        XCTAssertTrue(storedBackups.isEmpty)
    }

    @MainActor
    func testUndoRestoresActivityAndKeepsBackup() async throws {
        let original = PreviewSamples.coastalWalk
        let activities = MockActivityRepository(
            activities: [original]
        )
        let backups = MockBackupRepository()
        let replace = ReplaceActivityUseCase(
            activityRepository: activities,
            backupRepository: backups
        )
        let undo = UndoReplaceUseCase(
            activityRepository: activities
        )

        let savedOriginal = try await replace.execute(
            activity: original,
            with: PreviewSamples.australianMuseum
        )
        try await undo.execute(originalActivity: savedOriginal)

        let storedActivities = try await activities.fetchActivities(
            tripId: original.tripId
        )
        let storedBackups = try await backups.fetchBackups(
            tripId: original.tripId
        )

        XCTAssertEqual(storedActivities, [original])
        XCTAssertEqual(storedBackups.count, 1)
        XCTAssertEqual(
            storedBackups.first?.content,
            .activity(original)
        )
    }
}
