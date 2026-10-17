// Module: M4 tests – BackupsListViewModel: day headers, summary, rows, delete and errors.

import XCTest
@testable import PlanShift

@MainActor
final class BackupsListViewModelTests: XCTestCase {
    // MARK: - Fixed calendar, dates and data

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Australia/Sydney")!
        return calendar
    }()

    /// A fixed date in November 2026, Sydney time.
    private func date(day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute))!
    }

    /// Fri 13 Nov – Sun 15 Nov 2026.
    private lazy var trip = Trip(name: "Sydney Trip", startDate: date(day: 13), endDate: date(day: 15))

    /// A repository whose fetch always fails (MockBackupRepository cannot throw on fetch).
    private struct FailingBackupRepository: BackupRepository {
        func fetchBackups(tripId: UUID) async throws -> [BackupOption] { throw DomainError.persistenceFailure }
        func save(_ backup: BackupOption) async throws {}
        func delete(id: UUID) async throws {}
        func exists(placeId: UUID, tripId: UUID) async throws -> Bool { false }
    }

    private func makeViewModel(_ repository: any BackupRepository) -> BackupsListViewModel {
        BackupsListViewModel(
            fetchBackups: FetchBackupsUseCase(repository: repository, calendar: calendar),
            removeBackup: RemoveBackupUseCase(repository: repository),
            calendar: calendar
        )
    }

    private func makePlaceBackup(day: Int, name: String, savedHour: Int = 9) -> BackupOption {
        let place = Place(
            name: name,
            suburb: "Sydney",
            setting: .indoor,
            cost: 0,
            durationMinutes: 90,
            latitude: -33.8743,
            longitude: 151.2134,
            openingHour: 10,
            closingHour: 17,
            imageName: "museum",
            suitableDisruptions: []
        )
        return BackupOption(
            tripId: trip.id,
            content: .place(place),
            dayDate: date(day: day),
            savedAt: date(day: 1, hour: savedHour)
        )
    }

    private func makeActivityBackup(day: Int) -> BackupOption {
        let activity = ItineraryActivity(
            tripId: trip.id,
            name: "Taronga Zoo",
            date: date(day: day),
            startTime: date(day: day, hour: 13, minute: 30),
            endTime: date(day: day, hour: 16, minute: 30),
            locationName: "Mosman",
            latitude: -33.8435,
            longitude: 151.2413,
            setting: .outdoor,
            estimatedCost: 51
        )
        return BackupOption(tripId: trip.id, content: .activity(activity), dayDate: date(day: day), savedAt: date(day: 1))
    }

    // MARK: - Tests

    func testSectionsHaveTripDayHeaders() async {
        let repository = MockBackupRepository(backups: [
            makePlaceBackup(day: 14, name: "Museum"),
            makePlaceBackup(day: 13, name: "Gallery"),
        ])
        let viewModel = makeViewModel(repository)

        await viewModel.load(trip: trip)

        XCTAssertEqual(viewModel.sections.map(\.header), ["DAY 1 · FRI 13 NOV", "DAY 2 · SAT 14 NOV"])
        XCTAssertEqual(viewModel.sections.first?.rows.map(\.title), ["Gallery"])
        XCTAssertNil(viewModel.errorMessage)
    }

    func testSummaryAndCountForSeveralBackups() async {
        let repository = MockBackupRepository(backups: [
            makePlaceBackup(day: 13, name: "A", savedHour: 8),
            makePlaceBackup(day: 13, name: "B", savedHour: 9),
            makePlaceBackup(day: 14, name: "C"),
            makePlaceBackup(day: 15, name: "D"),
        ])
        let viewModel = makeViewModel(repository)

        await viewModel.load(trip: trip)

        XCTAssertEqual(viewModel.totalCount, 4)
        XCTAssertEqual(viewModel.summaryText, "4 saved for Sydney Trip")
    }

    func testSummaryForOneBackup() async {
        let viewModel = makeViewModel(MockBackupRepository(backups: [makePlaceBackup(day: 13, name: "A")]))

        await viewModel.load(trip: trip)

        XCTAssertEqual(viewModel.totalCount, 1)
        XCTAssertEqual(viewModel.summaryText, "1 saved for Sydney Trip")
    }

    func testEmptyTripIsEmpty() async {
        let viewModel = makeViewModel(MockBackupRepository())

        await viewModel.load(trip: trip)

        XCTAssertTrue(viewModel.isEmpty)
        XCTAssertTrue(viewModel.sections.isEmpty)
        XCTAssertEqual(viewModel.totalCount, 0)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testPlaceRowHasTagsAndImage() async throws {
        let viewModel = makeViewModel(MockBackupRepository(backups: [makePlaceBackup(day: 13, name: "Museum")]))

        await viewModel.load(trip: trip)

        let row = try XCTUnwrap(viewModel.sections.first?.rows.first)
        XCTAssertEqual(row.tags, ["Indoor", "Free entry", "~1.5 hrs"])
        XCTAssertEqual(row.imageName, "museum")
        XCTAssertFalse(row.isFromReplacedActivity)
    }

    func testReplacedActivityRowIsMarked() async throws {
        let viewModel = makeViewModel(MockBackupRepository(backups: [makeActivityBackup(day: 14)]))

        await viewModel.load(trip: trip)

        let row = try XCTUnwrap(viewModel.sections.first?.rows.first)
        XCTAssertEqual(row.title, "Taronga Zoo")
        XCTAssertTrue(row.isFromReplacedActivity)
        XCTAssertEqual(row.tags, ["Outdoor", "$51", "~3 hrs"])
        XCTAssertNil(row.imageName)
    }

    func testDeleteRemovesRowAndUpdatesCount() async {
        let removed = makePlaceBackup(day: 13, name: "A")
        let kept = makePlaceBackup(day: 14, name: "B")
        let viewModel = makeViewModel(MockBackupRepository(backups: [removed, kept]))
        await viewModel.load(trip: trip)

        await viewModel.delete(backupId: removed.id)

        // Day 1 had only that backup, so its section is gone too.
        XCTAssertEqual(viewModel.sections.map(\.header), ["DAY 2 · SAT 14 NOV"])
        XCTAssertEqual(viewModel.totalCount, 1)
        XCTAssertEqual(viewModel.summaryText, "1 saved for Sydney Trip")
    }

    func testFailedDeleteKeepsListAndSetsError() async {
        let backup = makePlaceBackup(day: 13, name: "A")
        let repository = MockBackupRepository(backups: [backup], deleteError: .persistenceFailure)
        let viewModel = makeViewModel(repository)
        await viewModel.load(trip: trip)

        await viewModel.delete(backupId: backup.id)

        XCTAssertEqual(viewModel.totalCount, 1)
        XCTAssertEqual(viewModel.errorMessage, DomainError.persistenceFailure.localizedDescription)
    }

    func testFailedLoadSetsErrorMessage() async {
        let viewModel = makeViewModel(FailingBackupRepository())

        await viewModel.load(trip: trip)

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.sections.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
    }
}
