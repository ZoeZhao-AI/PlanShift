// Module: M4 tests – CoreDataBackupRepository against an in-memory store. Fixed dates, no real clock.

import CoreData
import XCTest
@testable import PlanShift

@MainActor
final class CoreDataBackupRepositoryTests: XCTestCase {
    // MARK: - Fixed calendar, dates and data

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Australia/Sydney")!
        return calendar
    }()

    private let tripId = UUID(uuidString: "00000000-0000-0000-0000-0000000000B1")!
    private let otherTripId = UUID(uuidString: "00000000-0000-0000-0000-0000000000B2")!

    /// Kept alive for the whole test so the in-memory store is not torn down.
    private var persistence: PersistenceController!
    private var repository: CoreDataBackupRepository!

    override func setUp() async throws {
        persistence = try PersistenceController(inMemory: true)
        repository = CoreDataBackupRepository(container: persistence.container)
    }

    override func tearDown() async throws {
        repository = nil
        persistence = nil
    }

    private func date(day: Int = 14, hour: Int = 0, minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute))!
    }

    private func makePlace(name: String = "Australian Museum") -> Place {
        Place(
            name: name,
            suburb: "Sydney",
            setting: .indoor,
            cost: 15.5,
            durationMinutes: 90,
            latitude: -33.8743,
            longitude: 151.2134,
            openingHour: 10,
            closingHour: 17,
            imageName: "australian_museum",
            suitableDisruptions: [.rainyWeather]
        )
    }

    private func makeActivity() -> ItineraryActivity {
        ItineraryActivity(
            tripId: tripId,
            name: "Taronga Zoo",
            date: date(),
            startTime: date(hour: 13, minute: 30),
            endTime: date(hour: 16, minute: 30),
            locationName: "Mosman",
            latitude: -33.8435,
            longitude: 151.2413,
            setting: .outdoor,
            estimatedCost: 51.99
        )
    }

    private func makeBackup(
        tripId: UUID? = nil,
        content: BackupContent? = nil,
        savedAt: Date? = nil
    ) -> BackupOption {
        BackupOption(
            tripId: tripId ?? self.tripId,
            content: content ?? .place(makePlace()),
            dayDate: date(),
            savedAt: savedAt ?? date(hour: 9)
        )
    }

    // MARK: - Save and fetch

    func testSaveThenFetchReturnsSamePlaceBackup() async throws {
        let backup = makeBackup(content: .place(makePlace()))

        try await repository.save(backup)
        let result = try await repository.fetchBackups(tripId: tripId)

        XCTAssertEqual(result, [backup])
    }

    func testSaveThenFetchReturnsSameActivityBackup() async throws {
        let backup = makeBackup(content: .activity(makeActivity()))

        try await repository.save(backup)
        let result = try await repository.fetchBackups(tripId: tripId)

        XCTAssertEqual(result, [backup])
    }

    func testFetchReturnsOnlyThatTripsBackupsNewestFirst() async throws {
        let older = makeBackup(savedAt: date(hour: 9))
        let newest = makeBackup(content: .activity(makeActivity()), savedAt: date(hour: 11))
        let middle = makeBackup(savedAt: date(hour: 10))
        let otherTrip = makeBackup(tripId: otherTripId, savedAt: date(hour: 12))

        for backup in [older, otherTrip, newest, middle] {
            try await repository.save(backup)
        }
        let result = try await repository.fetchBackups(tripId: tripId)

        XCTAssertEqual(result, [newest, middle, older])
    }

    func testFetchReturnsEmptyForTripWithoutBackups() async throws {
        try await repository.save(makeBackup())

        let result = try await repository.fetchBackups(tripId: otherTripId)

        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Update

    func testSavingSameIdTwiceUpdatesInsteadOfAddingRow() async throws {
        let original = makeBackup()
        try await repository.save(original)

        var updated = original
        updated.content = .place(makePlace(name: "Updated Museum"))
        updated.savedAt = date(hour: 12)
        try await repository.save(updated)

        let result = try await repository.fetchBackups(tripId: tripId)
        XCTAssertEqual(result, [updated])
        XCTAssertEqual(try rowCount(), 1)
    }

    func testUpdatingPlaceToActivityClearsPlaceId() async throws {
        let place = makePlace()
        let original = makeBackup(content: .place(place))
        try await repository.save(original)

        var updated = original
        updated.content = .activity(makeActivity())
        try await repository.save(updated)

        let exists = try await repository.exists(placeId: place.id, tripId: tripId)
        XCTAssertFalse(exists)
    }

    // MARK: - Delete

    func testDeleteRemovesOnlyThatBackup() async throws {
        let removed = makeBackup(savedAt: date(hour: 9))
        let kept = makeBackup(savedAt: date(hour: 10))
        try await repository.save(removed)
        try await repository.save(kept)

        try await repository.delete(id: removed.id)
        let result = try await repository.fetchBackups(tripId: tripId)

        XCTAssertEqual(result, [kept])
    }

    func testDeleteMissingIdDoesNothing() async throws {
        let backup = makeBackup()
        try await repository.save(backup)

        try await repository.delete(id: UUID())
        let result = try await repository.fetchBackups(tripId: tripId)

        XCTAssertEqual(result, [backup])
    }

    // MARK: - Exists

    func testExistsIsTrueForSavedPlace() async throws {
        let place = makePlace()
        try await repository.save(makeBackup(content: .place(place)))

        let result = try await repository.exists(placeId: place.id, tripId: tripId)

        XCTAssertTrue(result)
    }

    func testExistsIsFalseForAnotherTrip() async throws {
        let place = makePlace()
        try await repository.save(makeBackup(content: .place(place)))

        let result = try await repository.exists(placeId: place.id, tripId: otherTripId)

        XCTAssertFalse(result)
    }

    func testExistsIsFalseWhenOnlyActivityBackupExists() async throws {
        let activity = makeActivity()
        try await repository.save(makeBackup(content: .activity(activity)))

        let result = try await repository.exists(placeId: activity.id, tripId: tripId)

        XCTAssertFalse(result)
    }

    // MARK: - Errors

    func testUnreadableContentThrowsPersistenceFailure() async throws {
        let backup = makeBackup()
        try await repository.save(backup)
        try corruptContentData(of: backup.id)

        do {
            _ = try await repository.fetchBackups(tripId: tripId)
            XCTFail("Expected persistenceFailure")
        } catch {
            XCTAssertEqual(error as? DomainError, .persistenceFailure)
        }
    }

    // MARK: - Helpers

    private func rowCount() throws -> Int {
        try persistence.viewContext.count(for: BackupEntity.fetchRequest())
    }

    /// Writes bytes that are not valid JSON straight into the row, as a damaged store would.
    private func corruptContentData(of id: UUID) throws {
        let context = persistence.viewContext
        let request = BackupEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        let entity = try XCTUnwrap(context.fetch(request).first)
        entity.contentData = Data("not json".utf8)
        try context.save()
    }
}
