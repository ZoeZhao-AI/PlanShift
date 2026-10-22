// Module: M4 tests – UseBackupViewModel: default day, switching day, selection and Continue.

import XCTest
@testable import PlanShift

@MainActor
final class UseBackupViewModelTests: XCTestCase {
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

    private func makeActivity(_ name: String, day: Int, hour: Int) -> ItineraryActivity {
        ItineraryActivity(
            tripId: trip.id,
            name: name,
            date: date(day: day),
            startTime: date(day: day, hour: hour),
            endTime: date(day: day, hour: hour + 3),
            locationName: name,
            latitude: -33.86,
            longitude: 151.21,
            setting: .outdoor,
            estimatedCost: 0
        )
    }

    private func makePlaceBackup(day: Int) -> BackupOption {
        let place = Place(
            name: "Australian Museum",
            suburb: "Sydney",
            setting: .indoor,
            cost: 0,
            durationMinutes: 120,
            latitude: -33.8743,
            longitude: 151.2132,
            openingHour: 10,
            closingHour: 17,
            imageName: "australian-museum",
            suitableDisruptions: []
        )
        return BackupOption(tripId: trip.id, content: .place(place), dayDate: date(day: day), savedAt: date(day: 1))
    }

    /// Day 1 (13th): nothing. Day 2 (14th): walk and zoo. Day 3 (15th): beach.
    private lazy var walk = makeActivity("Coastal Walk", day: 14, hour: 9)
    private lazy var zoo = makeActivity("Taronga Zoo", day: 14, hour: 13)
    private lazy var beach = makeActivity("Manly Beach", day: 15, hour: 10)

    private func makeViewModel(backup: BackupOption, activities: [ItineraryActivity]? = nil) -> UseBackupViewModel {
        let repository = MockActivityRepository(activities: activities ?? [zoo, beach, walk])
        return UseBackupViewModel(
            backup: backup,
            fetchDayActivities: FetchDayActivitiesUseCase(repository: repository, calendar: calendar),
            calendar: calendar
        )
    }

    // MARK: - Tests

    func testBuildsTripDaysWithShortDates() async {
        let viewModel = makeViewModel(backup: makePlaceBackup(day: 14))

        await viewModel.load(trip: trip)

        XCTAssertEqual(viewModel.days.map(\.title), ["Day 1", "Day 2", "Day 3"])
        XCTAssertEqual(viewModel.days.map(\.shortDate), ["Fri 13", "Sat 14", "Sun 15"])
    }

    func testDefaultDayIsTheBackupsDay() async {
        let viewModel = makeViewModel(backup: makePlaceBackup(day: 14))

        await viewModel.load(trip: trip)

        XCTAssertEqual(viewModel.selectedDay, date(day: 14))
        XCTAssertEqual(viewModel.activityRows.map(\.title), ["Coastal Walk", "Taronga Zoo"])
        XCTAssertEqual(viewModel.activityRows.first?.timeRange, "09:00 – 12:00")
    }

    func testBackupDayOutsideTripFallsBackToDayOne() async {
        let viewModel = makeViewModel(backup: makePlaceBackup(day: 20))

        await viewModel.load(trip: trip)

        XCTAssertEqual(viewModel.selectedDay, date(day: 13))
    }

    func testSwitchingDayLoadsItsActivitiesAndClearsSelection() async {
        let viewModel = makeViewModel(backup: makePlaceBackup(day: 14))
        await viewModel.load(trip: trip)
        viewModel.selectActivity(id: walk.id)

        await viewModel.selectDay(date(day: 15))

        XCTAssertEqual(viewModel.activityRows.map(\.title), ["Manly Beach"])
        XCTAssertNil(viewModel.selectedActivityId)
        XCTAssertFalse(viewModel.canContinue)
    }

    func testContinueIsDisabledUntilAnActivityIsSelected() async {
        let viewModel = makeViewModel(backup: makePlaceBackup(day: 14))
        await viewModel.load(trip: trip)

        XCTAssertFalse(viewModel.canContinue)

        viewModel.selectActivity(id: zoo.id)

        XCTAssertTrue(viewModel.canContinue)
        XCTAssertEqual(viewModel.selectedActivity, zoo)
    }

    func testOnlyOneActivityIsSelectedAtATime() async {
        let viewModel = makeViewModel(backup: makePlaceBackup(day: 14))
        await viewModel.load(trip: trip)

        viewModel.selectActivity(id: walk.id)
        viewModel.selectActivity(id: zoo.id)

        XCTAssertEqual(viewModel.selectedActivityId, zoo.id)
    }

    func testEmptyDayShowsEmptyMessage() async {
        let viewModel = makeViewModel(backup: makePlaceBackup(day: 13))

        await viewModel.load(trip: trip)

        XCTAssertTrue(viewModel.isDayEmpty)
        XCTAssertTrue(viewModel.activityRows.isEmpty)
        XCTAssertFalse(viewModel.emptyDayMessage.isEmpty)
        XCTAssertFalse(viewModel.canContinue)
    }

    func testOriginalPlanBackupCanContinueWithItsDetails() async throws {
        let backup = BackupOption(tripId: trip.id, content: .activity(zoo), dayDate: date(day: 14))
        let viewModel = makeViewModel(backup: backup)
        await viewModel.load(trip: trip)

        viewModel.selectActivity(id: walk.id)

        let place = try XCTUnwrap(viewModel.place)
        XCTAssertEqual(viewModel.originalPlan, zoo)
        XCTAssertEqual(place.name, zoo.name)
        XCTAssertEqual(place.suburb, zoo.locationName)
        XCTAssertEqual(place.durationMinutes, 180)
        XCTAssertTrue(viewModel.canContinue)
        XCTAssertTrue(viewModel.backupRow.isFromReplacedActivity)
    }

    func testOriginalPlanPreselectsTheActivityThatReplacedIt() async {
        var replacement = zoo
        replacement.name = "Australian Museum"
        replacement.locationName = "Australian Museum"
        let backup = BackupOption(tripId: trip.id, content: .activity(zoo), dayDate: date(day: 14))
        let viewModel = makeViewModel(backup: backup, activities: [replacement, beach, walk])

        await viewModel.load(trip: trip)

        XCTAssertEqual(viewModel.selectedDay, date(day: 14))
        XCTAssertEqual(viewModel.selectedActivity, replacement)
        XCTAssertTrue(viewModel.canContinue)
    }

    func testOriginalPlanBackInTheItineraryIsNotPreselected() async {
        // After Undo the stored activity equals the original plan again.
        let backup = BackupOption(tripId: trip.id, content: .activity(zoo), dayDate: date(day: 14))
        let viewModel = makeViewModel(backup: backup)

        await viewModel.load(trip: trip)

        XCTAssertNil(viewModel.selectedActivityId)
        XCTAssertFalse(viewModel.canContinue)
    }

    func testPlaceBackupHasNoOriginalPlan() {
        let viewModel = makeViewModel(backup: makePlaceBackup(day: 14))

        XCTAssertNil(viewModel.originalPlan)
    }
}
