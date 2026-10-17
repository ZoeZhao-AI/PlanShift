// Module: M4 tests – FetchDayActivitiesUseCase: one trip, one day, sorted by start time.

import XCTest
@testable import PlanShift

final class FetchDayActivitiesUseCaseTests: XCTestCase {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Australia/Sydney")!
        return calendar
    }()

    private let tripId = UUID(uuidString: "00000000-0000-0000-0000-0000000000C1")!

    /// A fixed date in November 2026, Sydney time.
    private func date(day: Int, hour: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour))!
    }

    private func makeActivity(_ name: String, day: Int, hour: Int, tripId: UUID? = nil) -> ItineraryActivity {
        ItineraryActivity(
            tripId: tripId ?? self.tripId,
            name: name,
            date: date(day: day),
            startTime: date(day: day, hour: hour),
            endTime: date(day: day, hour: hour + 1),
            locationName: name,
            latitude: -33.86,
            longitude: 151.21,
            setting: .outdoor,
            estimatedCost: 0
        )
    }

    private func fetch(_ activities: [ItineraryActivity], day: Int) async throws -> [String] {
        let useCase = FetchDayActivitiesUseCase(
            repository: MockActivityRepository(activities: activities),
            calendar: calendar
        )
        return try await useCase.execute(tripId: tripId, day: date(day: day, hour: 15)).map(\.name)
    }

    func testReturnsOnlyThatDaysActivitiesEarliestFirst() async throws {
        let names = try await fetch([
            makeActivity("Lunch", day: 14, hour: 12),
            makeActivity("Walk", day: 14, hour: 9),
            makeActivity("Zoo", day: 15, hour: 9),
        ], day: 14)

        XCTAssertEqual(names, ["Walk", "Lunch"])
    }

    func testIgnoresOtherTrips() async throws {
        let otherTrip = UUID(uuidString: "00000000-0000-0000-0000-0000000000C2")!
        let names = try await fetch([
            makeActivity("Mine", day: 14, hour: 9),
            makeActivity("Theirs", day: 14, hour: 10, tripId: otherTrip),
        ], day: 14)

        XCTAssertEqual(names, ["Mine"])
    }

    func testDayWithoutActivitiesReturnsEmpty() async throws {
        let names = try await fetch([makeActivity("Walk", day: 14, hour: 9)], day: 13)

        XCTAssertTrue(names.isEmpty)
    }
}
