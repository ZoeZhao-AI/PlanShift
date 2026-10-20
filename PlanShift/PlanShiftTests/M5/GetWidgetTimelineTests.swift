import XCTest
@testable import PlanShift

final class GetWidgetTimelineTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let tripId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    func testLoadsCurrentTripAndBuildsTimelineFromUnsortedActivities() async throws {
        let first = activity(start: 60)
        let second = activity(start: 120)
        var otherTrip = activity(start: 1)
        otherTrip.tripId = UUID()
        let repository = WidgetActivitiesStub(items: [second, otherTrip, first])
        let result = try await useCase(activities: repository).execute()
        let requestedTrips = await repository.requestedTripIds
        XCTAssertEqual(requestedTrips, [tripId])
        XCTAssertEqual(result.entries, [
            .init(date: now, state: .activity(first)),
            .init(date: first.startTime, state: .activity(second)),
            .init(date: second.startTime, state: .empty)
        ])
    }

    func testNoCurrentTripReturnsEmptyWithoutReadingActivities() async throws {
        let repository = WidgetActivitiesStub(error: WidgetReadError.unavailable)
        let instant = now
        let useCase = GetWidgetTimeline(trips: MockTripRepository(), activities: repository, now: { instant })
        let result = try await useCase.execute()
        let requestedTrips = await repository.requestedTripIds
        XCTAssertEqual(result, .empty(now: now))
        XCTAssertTrue(requestedTrips.isEmpty)
    }

    func testEmptyOrAlreadyStartedActivitiesReturnEmpty() async throws {
        for items in [[], [activity(start: -60), activity(start: 0)]] {
            let result = try await useCase(activities: WidgetActivitiesStub(items: items)).execute()
            XCTAssertEqual(result, .empty(now: now))
        }
    }

    func testTripReadErrorDoesNotBecomeEmptyOrReadActivities() async {
        let errors: [any Error] = [DomainError.persistenceFailure, WidgetReadError.unavailable]
        for error in errors {
            let activities = WidgetActivitiesStub()
            let useCase = GetWidgetTimeline(trips: WidgetFailingTrips(error: error), activities: activities)
            do {
                _ = try await useCase.execute()
                XCTFail("Expected trip read failure")
            } catch {
                XCTAssertEqual(error as? DomainError, .persistenceFailure)
            }
            let requestedTrips = await activities.requestedTripIds
            XCTAssertTrue(requestedTrips.isEmpty)
        }
    }

    func testActivityDomainErrorIsPreserved() async {
        do {
            _ = try await useCase(activities: WidgetActivitiesStub(error: DomainError.activityNotFound)).execute()
            XCTFail("Expected activity read failure")
        } catch {
            XCTAssertEqual(error as? DomainError, .activityNotFound)
        }
    }

    func testUnexpectedActivityErrorMapsToPersistenceFailure() async {
        do {
            _ = try await useCase(activities: WidgetActivitiesStub(error: WidgetReadError.unavailable)).execute()
            XCTFail("Expected activity read failure")
        } catch {
            XCTAssertEqual(error as? DomainError, .persistenceFailure)
        }
    }

    func testCancellationFromEitherRepositoryIsPreserved() async {
        let loaders = [
            GetWidgetTimeline(trips: WidgetFailingTrips(error: CancellationError()), activities: WidgetActivitiesStub()),
            useCase(activities: WidgetActivitiesStub(error: CancellationError()))
        ]
        for loader in loaders {
            do {
                _ = try await loader.execute()
                XCTFail("Expected cancellation")
            } catch {
                XCTAssertTrue(error is CancellationError)
            }
        }
    }

    func testClockIsReadAfterActivitiesLoad() async throws {
        let loadedTime = now.addingTimeInterval(90)
        let future = activity(start: 120)
        let repository = WidgetActivitiesStub(items: [activity(start: 60), future])
        // The clock checks the repository's completion marker; no real delays are needed.
        let clock = WidgetLoadClock(initial: now, afterLoading: loadedTime)
        await repository.setOnRead { clock.didLoad() }
        let loader = GetWidgetTimeline(trips: MockTripRepository(currentTrip: trip),
                                       activities: repository, now: { clock.read() })
        let result = try await loader.execute()
        XCTAssertEqual(result.entries.first?.date, loadedTime)
        XCTAssertEqual(result.entries.first?.state, .activity(future))
        XCTAssertEqual(clock.readCount, 1)
    }

    private var trip: Trip {
        Trip(id: tripId, name: "Sydney", startDate: now, endDate: now.addingTimeInterval(86400))
    }

    private func useCase(activities: WidgetActivitiesStub) -> GetWidgetTimeline {
        let instant = now
        return GetWidgetTimeline(trips: MockTripRepository(currentTrip: trip), activities: activities, now: { instant })
    }

    private func activity(start offset: TimeInterval) -> ItineraryActivity {
        ItineraryActivity(tripId: tripId, name: "Museum", date: now,
                          startTime: now.addingTimeInterval(offset), endTime: now.addingTimeInterval(offset + 3600),
                          locationName: "Sydney", latitude: -33.87, longitude: 151.21,
                          setting: .indoor, estimatedCost: 0)
    }
}

private nonisolated enum WidgetReadError: Error { case unavailable, unexpectedCall }

private nonisolated struct WidgetFailingTrips: TripRepository {
    let error: any Error
    func fetchCurrentTrip() async throws -> Trip? { throw error }
    func createTrip(_ trip: Trip) async throws { throw WidgetReadError.unexpectedCall }
    func updateTrip(_ trip: Trip) async throws { throw WidgetReadError.unexpectedCall }
}

private actor WidgetActivitiesStub: ActivityRepository {
    private let items: [ItineraryActivity]
    private let error: (any Error)?
    private var onRead: (@Sendable () -> Void)?
    private(set) var requestedTripIds: [UUID] = []

    init(items: [ItineraryActivity] = [], error: (any Error)? = nil) {
        self.items = items
        self.error = error
    }
    func setOnRead(_ action: @escaping @Sendable () -> Void) { onRead = action }
    func fetchActivities(tripId: UUID) async throws -> [ItineraryActivity] {
        requestedTripIds.append(tripId)
        if let error { throw error }
        onRead?()
        return items
    }
    func fetchActivities(on date: Date) async throws -> [ItineraryActivity] { throw WidgetReadError.unexpectedCall }
    func fetchNextUpcoming(after date: Date) async throws -> ItineraryActivity? { throw WidgetReadError.unexpectedCall }
    func add(_ activity: ItineraryActivity) async throws { throw WidgetReadError.unexpectedCall }
    func update(_ activity: ItineraryActivity) async throws { throw WidgetReadError.unexpectedCall }
    func delete(id: UUID) async throws { throw WidgetReadError.unexpectedCall }
}

/// Synchronous clock shared between the repository actor and the use case.
private nonisolated final class WidgetLoadClock: @unchecked Sendable {
    private let lock = NSLock()
    private let initial: Date
    private let afterLoading: Date
    private var loaded = false
    private var count = 0

    init(initial: Date, afterLoading: Date) {
        self.initial = initial
        self.afterLoading = afterLoading
    }
    var readCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return count
    }
    func didLoad() {
        lock.lock()
        defer { lock.unlock() }
        loaded = true
    }
    func read() -> Date {
        lock.lock()
        defer { lock.unlock() }
        count += 1
        return loaded ? afterLoading : initial
    }
}
