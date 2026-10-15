//
//  MockBackupRepositoryTests.swift
//  PlanShiftTests
//
//  Created by Chang Chia ming on 2026/10/15.
//

import Foundation
import XCTest
@testable import PlanShift

final class MockBackupRepositoryTests: XCTestCase {
    func testFetchReturnsEmptyWhenNoBackups() async throws {
        let repository = MockBackupRepository()

        let result = try await repository.fetchBackups(
            tripId: UUID()
        )

        XCTAssertTrue(result.isEmpty)
    }

    func testFetchFiltersByTripAndSortsNewestFirst() async throws {
        let tripId = UUID()
        let older = makeBackup(tripId: tripId)
        let newer = makeBackup(
            tripId: tripId,
            savedAt: baseDate.addingTimeInterval(60)
        )
        let otherTrip = makeBackup(
            savedAt: baseDate.addingTimeInterval(120)
        )
        let repository = MockBackupRepository(
            backups: [older, otherTrip, newer]
        )

        let result = try await repository.fetchBackups(
            tripId: tripId
        )

        XCTAssertEqual(result, [newer, older])
    }

    func testSaveAddsBackupAndPreservesExistingData() async throws {
        let tripId = UUID()
        let existing = makeBackup(tripId: tripId)
        let added = makeBackup(
            tripId: tripId,
            savedAt: baseDate.addingTimeInterval(60)
        )
        let repository = MockBackupRepository(
            backups: [existing]
        )

        try await repository.save(added)
        let result = try await repository.fetchBackups(
            tripId: tripId
        )

        XCTAssertEqual(result, [added, existing])
    }

    func testSaveUpdatesMatchingIDWithoutAddingDuplicate() async throws {
        let tripId = UUID()
        let original = makeBackup(tripId: tripId)
        let other = makeBackup(
            tripId: tripId,
            savedAt: baseDate.addingTimeInterval(60)
        )
        let repository = MockBackupRepository(
            backups: [original, other]
        )
        var updated = original
        updated.place.name = "Updated Museum"
        updated.savedAt = baseDate.addingTimeInterval(120)

        try await repository.save(updated)
        let result = try await repository.fetchBackups(
            tripId: tripId
        )

        XCTAssertEqual(result, [updated, other])
    }

    func testDeleteRemovesOnlyMatchingBackup() async throws {
        let tripId = UUID()
        let removed = makeBackup(tripId: tripId)
        let kept = makeBackup(tripId: tripId)
        let repository = MockBackupRepository(
            backups: [removed, kept]
        )

        try await repository.delete(id: removed.id)
        let result = try await repository.fetchBackups(
            tripId: tripId
        )

        XCTAssertEqual(result, [kept])
    }

    func testDeleteMissingIDPreservesData() async throws {
        let backup = makeBackup()
        let repository = MockBackupRepository(
            backups: [backup]
        )

        try await repository.delete(id: UUID())
        let result = try await repository.fetchBackups(
            tripId: backup.tripId
        )

        XCTAssertEqual(result, [backup])
    }

    func testExistsReturnsTrueForMatchingPlaceAndTrip() async throws {
        let backup = makeBackup()
        let repository = MockBackupRepository(
            backups: [backup]
        )

        let result = try await repository.exists(
            placeId: backup.place.id,
            tripId: backup.tripId
        )

        XCTAssertTrue(result)
    }

    func testExistsReturnsFalseForDifferentPlace() async throws {
        let backup = makeBackup()
        let repository = MockBackupRepository(
            backups: [backup]
        )

        let result = try await repository.exists(
            placeId: UUID(),
            tripId: backup.tripId
        )

        XCTAssertFalse(result)
    }

    func testExistsReturnsFalseForDifferentTrip() async throws {
        let backup = makeBackup()
        let repository = MockBackupRepository(
            backups: [backup]
        )

        let result = try await repository.exists(
            placeId: backup.place.id,
            tripId: UUID()
        )

        XCTAssertFalse(result)
    }

    func testExistsReturnsFalseWhenEmpty() async throws {
        let repository = MockBackupRepository()

        let result = try await repository.exists(
            placeId: UUID(),
            tripId: UUID()
        )

        XCTAssertFalse(result)
    }

    private var baseDate: Date {
        Date(timeIntervalSince1970: 1_800_000_000)
    }

    private func makeBackup(
        tripId: UUID = UUID(),
        savedAt: Date? = nil
    ) -> BackupOption {
        let place = Place(
            name: "Museum",
            suburb: "Sydney",
            setting: .indoor,
            cost: 0,
            durationMinutes: 60,
            latitude: -33.8688,
            longitude: 151.2093,
            openingHour: 9,
            closingHour: 17,
            imageName: "",
            suitableDisruptions: []
        )

        return BackupOption(
            tripId: tripId,
            place: place,
            dayDate: baseDate,
            savedAt: savedAt ?? baseDate
        )
    }
}
