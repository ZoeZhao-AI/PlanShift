// Module: M4 tests – Save, Fetch and Remove backup use cases. Fixed calendar and dates, no real clock.

import XCTest
@testable import PlanShift

final class M4BackupUseCaseTests: XCTestCase {
    // MARK: - Fixed calendar, dates and data

    /// Sydney time zone, so "start of day" is the same wherever the tests run.
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Australia/Sydney")!
        return calendar
    }()

    private let tripId = UUID(uuidString: "00000000-0000-0000-0000-0000000000B1")!

    /// A fixed date in November 2026, Sydney time.
    private func date(day: Int = 14, hour: Int = 0, minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute))!
    }

    private func makePlace(name: String = "Australian Museum") -> Place {
        Place(
            name: name,
            suburb: "Sydney",
            setting: .indoor,
            cost: 15,
            durationMinutes: 90,
            latitude: -33.8743,
            longitude: 151.2134,
            openingHour: 10,
            closingHour: 17,
            imageName: "",
            suitableDisruptions: []
        )
    }

    /// An activity on 14 Nov at 1:30 pm. Its `date` has a time of day on purpose,
    /// so the tests prove that saving keeps only the day.
    private func makeActivity(tripId: UUID? = nil) -> ItineraryActivity {
        ItineraryActivity(
            tripId: tripId ?? self.tripId,
            name: "Taronga Zoo",
            date: date(hour: 13, minute: 30),
            startTime: date(hour: 13, minute: 30),
            endTime: date(hour: 16, minute: 30),
            locationName: "Mosman",
            latitude: -33.8435,
            longitude: 151.2413,
            setting: .outdoor,
            estimatedCost: 51
        )
    }

    private func makeBackup(dayDate: Date, savedAt: Date, name: String = "Museum") -> BackupOption {
        BackupOption(tripId: tripId, content: .place(makePlace(name: name)), dayDate: dayDate, savedAt: savedAt)
    }

    private func makeSaver(_ repository: MockBackupRepository, now: Date? = nil) -> SaveBackupUseCase {
        let fixedNow = now ?? date(hour: 9)
        return SaveBackupUseCase(repository: repository, calendar: calendar, now: { fixedNow })
    }

    // MARK: - SaveBackupUseCase

    func testSaveStoresBackupWithTripDayAndNow() async throws {
        let repository = MockBackupRepository()
        let now = date(day: 10, hour: 8, minute: 15)
        let place = makePlace()
        let activity = makeActivity()

        try await makeSaver(repository, now: now).save(place: place, for: activity)

        let saved = try await repository.fetchBackups(tripId: tripId)
        XCTAssertEqual(saved.count, 1)
        let backup = try XCTUnwrap(saved.first)
        XCTAssertEqual(backup.content, .place(place))
        XCTAssertEqual(backup.tripId, activity.tripId)
        XCTAssertEqual(backup.dayDate, date(hour: 0))
        XCTAssertEqual(backup.savedAt, now)
    }

    func testSavingSamePlaceTwiceThrowsDuplicateAndKeepsOne() async throws {
        let repository = MockBackupRepository()
        let saver = makeSaver(repository)
        let place = makePlace()
        let activity = makeActivity()

        try await saver.save(place: place, for: activity)
        do {
            try await saver.save(place: place, for: activity)
            XCTFail("Expected duplicateBackup.")
        } catch {
            XCTAssertEqual(error as? DomainError, .duplicateBackup)
        }

        let saved = try await repository.fetchBackups(tripId: tripId)
        XCTAssertEqual(saved.count, 1)
    }

    func testIsSavedIsFalseBeforeAndTrueAfterSaving() async throws {
        let saver = makeSaver(MockBackupRepository())
        let place = makePlace()

        let before = try await saver.isSaved(placeId: place.id, tripId: tripId)
        try await saver.save(place: place, for: makeActivity())
        let after = try await saver.isSaved(placeId: place.id, tripId: tripId)

        XCTAssertFalse(before)
        XCTAssertTrue(after)
    }

    func testSamePlaceCanBeSavedForTwoTrips() async throws {
        let repository = MockBackupRepository()
        let saver = makeSaver(repository)
        let place = makePlace()
        let otherTripId = UUID(uuidString: "00000000-0000-0000-0000-0000000000B2")!

        try await saver.save(place: place, for: makeActivity())
        try await saver.save(place: place, for: makeActivity(tripId: otherTripId))

        let firstTrip = try await repository.fetchBackups(tripId: tripId)
        let secondTrip = try await repository.fetchBackups(tripId: otherTripId)
        XCTAssertEqual(firstTrip.count, 1)
        XCTAssertEqual(secondTrip.count, 1)
    }

    // MARK: - FetchBackupsUseCase

    func testFetchGroupsByDayEarliestFirstAndNewestSavedFirst() async throws {
        let day15Older = makeBackup(dayDate: date(day: 15), savedAt: date(day: 1, hour: 9), name: "A")
        let day15Newer = makeBackup(dayDate: date(day: 15), savedAt: date(day: 2, hour: 9), name: "B")
        let day14 = makeBackup(dayDate: date(day: 14), savedAt: date(day: 3, hour: 9), name: "C")
        let repository = MockBackupRepository(backups: [day15Older, day14, day15Newer])
        let fetch = FetchBackupsUseCase(repository: repository, calendar: calendar)

        let groups = try await fetch.execute(tripId: tripId)

        XCTAssertEqual(groups.map(\.dayDate), [date(day: 14), date(day: 15)])
        XCTAssertEqual(groups[0].backups, [day14])
        XCTAssertEqual(groups[1].backups, [day15Newer, day15Older])
    }

    func testFetchWithNoBackupsReturnsEmpty() async throws {
        let fetch = FetchBackupsUseCase(repository: MockBackupRepository(), calendar: calendar)

        let groups = try await fetch.execute(tripId: tripId)

        XCTAssertTrue(groups.isEmpty)
    }

    func testFetchGroupsBackupWithTimeOfDayIntoSameDay() async throws {
        let midnight = makeBackup(dayDate: date(day: 14), savedAt: date(day: 1, hour: 9), name: "A")
        let lunchtime = makeBackup(dayDate: date(day: 14, hour: 12, minute: 30), savedAt: date(day: 2, hour: 9), name: "B")
        let repository = MockBackupRepository(backups: [midnight, lunchtime])
        let fetch = FetchBackupsUseCase(repository: repository, calendar: calendar)

        let groups = try await fetch.execute(tripId: tripId)

        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups.first?.dayDate, date(day: 14))
        XCTAssertEqual(groups.first?.backups, [lunchtime, midnight])
    }

    // MARK: - RemoveBackupUseCase

    func testRemovedBackupIsNoLongerFetched() async throws {
        let removed = makeBackup(dayDate: date(day: 14), savedAt: date(day: 1, hour: 9), name: "A")
        let kept = makeBackup(dayDate: date(day: 14), savedAt: date(day: 2, hour: 9), name: "B")
        let repository = MockBackupRepository(backups: [removed, kept])
        let remove = RemoveBackupUseCase(repository: repository)
        let fetch = FetchBackupsUseCase(repository: repository, calendar: calendar)

        try await remove.execute(id: removed.id)

        let groups = try await fetch.execute(tripId: tripId)
        XCTAssertEqual(groups.flatMap(\.backups), [kept])
    }
}
