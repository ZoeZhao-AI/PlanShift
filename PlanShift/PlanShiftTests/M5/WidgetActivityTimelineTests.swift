import XCTest
@testable import PlanShift

final class WidgetActivityTimelineTests: XCTestCase {
    private let tripId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    func testUnsortedActivitiesProduceChronologicalTransitionsAndFinalEmptyState() {
        let first = activity(start: 60)
        let second = activity(start: 120)
        let last = activity(start: 180)
        let timeline = make([last, first, second])
        XCTAssertEqual(timeline.entries, [
            .init(date: now, state: .activity(first)),
            .init(date: first.startTime, state: .activity(second)),
            .init(date: second.startTime, state: .activity(last)),
            .init(date: last.startTime, state: .empty)
        ])
    }

    func testEmptyAndPastActivitiesProduceOneEmptyEntryWithFutureReload() {
        for activities in [[], [activity(start: -60), activity(start: 0)]] {
            let timeline = make(activities)
            XCTAssertEqual(timeline.entries, [.init(date: now, state: .empty)])
            XCTAssertGreaterThan(timeline.reloadAfter, now)
        }
    }

    func testAlreadyStartedActivityIsExcludedEvenWhileOngoing() {
        let ongoing = activity(start: -1)
        XCTAssertGreaterThan(ongoing.endTime, now)
        XCTAssertEqual(make([ongoing]).entries.first?.state, .empty)
    }

    func testExactBoundaryIsExcludedButFractionalFutureIsIncluded() {
        let future = activity(start: 0.001)
        let timeline = make([activity(start: 0), future])
        XCTAssertEqual(timeline.entries.first?.state, .activity(future))
        XCTAssertEqual(timeline.entries.last, .init(date: future.startTime, state: .empty))
    }

    func testOtherTripsDoNotAppearOrAddTransitions() {
        var other = activity(start: 1)
        other.tripId = UUID()
        let expected = activity(start: 60)
        XCTAssertEqual(make([other, expected]), make([expected]))
    }

    func testSimultaneousStartsHaveOneTransitionAndStableSelection() {
        let first = activity(start: 60, id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!)
        let sameTime = activity(start: 60, id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!)
        let later = activity(start: 120)
        let timeline = make([sameTime, later, first])
        XCTAssertEqual(timeline, make([later, first, sameTime]))
        XCTAssertEqual(timeline.entries, [
            .init(date: now, state: .activity(first)),
            .init(date: first.startTime, state: .activity(later)),
            .init(date: later.startTime, state: .empty)
        ])
    }

    func testReadFailureIsDistinctFromEmptyAndSchedulesRetry() {
        let failed = WidgetActivityTimeline.unavailable(now: now)
        XCTAssertEqual(failed.entries, [.init(date: now, state: .unavailable)])
        XCTAssertNotEqual(failed.entries, make([]).entries)
        XCTAssertGreaterThan(failed.reloadAfter, now)
        XCTAssertLessThan(failed.reloadAfter, make([]).reloadAfter)
    }

    func testKnownTransitionsRemainAvailableWhenReloadIsDelayed() {
        let first = activity(start: 3600)
        let second = activity(start: 7200)
        let timeline = make([second, first])
        XCTAssertLessThan(timeline.reloadAfter, first.startTime)
        // WidgetKit can use an already-supplied entry without running the provider again.
        let delayedTime = first.startTime.addingTimeInterval(60)
        let entry = timeline.entries.last { $0.date <= delayedTime }
        XCTAssertEqual(entry?.state, .activity(second))
    }

    func testDSTBoundaryUsesAbsoluteInstants() throws {
        let formatter = ISO8601DateFormatter()
        let cutoff = try XCTUnwrap(formatter.date(from: "2026-10-04T01:59:59+10:00"))
        var future = activity(start: 1)
        future.startTime = try XCTUnwrap(formatter.date(from: "2026-10-04T03:00:00+11:00"))
        let timeline = WidgetActivityTimeline.make(activities: [future], tripId: tripId, now: cutoff)
        XCTAssertEqual(timeline.entries[1].date.timeIntervalSince(timeline.entries[0].date), 1)
    }

    private func make(_ activities: [ItineraryActivity]) -> WidgetActivityTimeline {
        .make(activities: activities, tripId: tripId, now: now)
    }

    private func activity(start offset: TimeInterval, id: UUID = UUID()) -> ItineraryActivity {
        ItineraryActivity(id: id, tripId: tripId, name: "Museum", date: now,
                          startTime: now.addingTimeInterval(offset),
                          endTime: now.addingTimeInterval(offset + 3600),
                          locationName: "Sydney", latitude: -33.87, longitude: 151.21,
                          setting: .indoor, estimatedCost: 0)
    }
}
