import XCTest
@testable import PlanShift

final class GetNextActivityTests: XCTestCase {
    private let tripId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    func testChoosesEarliestFromUnsortedActivities() async throws {
        let earliest = activity(start: 60)
        let repository = M5ActivityStub(activities: [activity(start: 500), earliest, activity(start: 120)])
        let result = try await useCase(repository).execute(tripId: tripId)
        XCTAssertEqual(result, earliest)
    }

    func testEmptyRepositoryReturnsNil() async throws {
        let result = try await useCase(M5ActivityStub()).execute(tripId: tripId)
        XCTAssertNil(result)
    }

    func testPastAndAlreadyStartedActivitiesReturnNil() async throws {
        // The second activity is ongoing, but has already started.
        let repository = M5ActivityStub(activities: [activity(start: -7200), activity(start: -60)])
        let result = try await useCase(repository).execute(tripId: tripId)
        XCTAssertNil(result)
    }

    func testExactBoundaryIsExcludedAndFractionalFutureIsIncluded() async throws {
        let future = activity(start: 0.001)
        let repository = M5ActivityStub(activities: [activity(start: 0), future])
        let result = try await useCase(repository).execute(tripId: tripId)
        XCTAssertEqual(result, future)
    }

    func testOnlyRequestedTripIsConsidered() async throws {
        var otherTrip = activity(start: 1)
        otherTrip.tripId = UUID()
        let expected = activity(start: 120)
        let result = try await useCase(M5ActivityStub(activities: [otherTrip, expected])).execute(tripId: tripId)
        XCTAssertEqual(result, expected)
    }

    func testEqualStartTimesHaveStableOrder() async throws {
        let first = activity(start: 60, id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!)
        let second = activity(start: 60, id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!)
        for activities in [[first, second], [second, first]] {
            let result = try await useCase(M5ActivityStub(activities: activities)).execute(tripId: tripId)
            XCTAssertEqual(result, first)
        }
    }

    func testComparesAbsoluteInstantsAcrossTimeZones() async throws {
        let formatter = ISO8601DateFormatter()
        let cutoff = try XCTUnwrap(formatter.date(from: "2026-10-04T01:59:59+10:00"))
        var boundary = activity(start: 0)
        boundary.startTime = try XCTUnwrap(formatter.date(from: "2026-10-03T15:59:59Z"))
        var future = activity(start: 1)
        future.startTime = try XCTUnwrap(formatter.date(from: "2026-10-04T03:00:00+11:00"))
        let useCase = GetNextActivity(repository: M5ActivityStub(activities: [future, boundary]), now: { cutoff })
        let result = try await useCase.execute(tripId: tripId)
        XCTAssertEqual(result, future)
    }

    func testDomainErrorIsPreservedInsteadOfReturningEmpty() async {
        do {
            _ = try await useCase(M5ActivityStub(error: DomainError.persistenceFailure)).execute(tripId: tripId)
            XCTFail("Expected repository failure")
        } catch {
            XCTAssertEqual(error as? DomainError, .persistenceFailure)
        }
    }

    func testUnexpectedRepositoryErrorMapsToPersistenceFailure() async {
        do {
            _ = try await useCase(M5ActivityStub(error: M5RepositoryError.offline)).execute(tripId: tripId)
            XCTFail("Expected repository failure")
        } catch {
            XCTAssertEqual(error as? DomainError, .persistenceFailure)
        }
    }

    func testCancellationRemainsCancellation() async {
        do {
            _ = try await useCase(M5ActivityStub(error: CancellationError())).execute(tripId: tripId)
            XCTFail("Expected cancellation")
        } catch {
            XCTAssertTrue(error is CancellationError)
        }
    }

    private func useCase(_ repository: M5ActivityStub) -> GetNextActivity {
        let instant = now
        return GetNextActivity(repository: repository, now: { instant })
    }

    private func activity(start offset: TimeInterval, id: UUID = UUID()) -> ItineraryActivity {
        ItineraryActivity(id: id, tripId: tripId, name: "Museum", date: now,
                          startTime: now.addingTimeInterval(offset),
                          endTime: now.addingTimeInterval(offset + 3600),
                          locationName: "Sydney", latitude: -33.87, longitude: 151.21,
                          setting: .indoor, estimatedCost: 0)
    }
}

private nonisolated enum M5RepositoryError: Error { case offline, unexpectedCall }

/// Deliberately returns unsorted data so the use case's selection is exercised.
private nonisolated struct M5ActivityStub: ActivityRepository {
    var activities: [ItineraryActivity] = []
    var error: (any Error)?

    func fetchActivities(tripId: UUID) async throws -> [ItineraryActivity] {
        if let error { throw error }
        return activities
    }
    func fetchActivities(on date: Date) async throws -> [ItineraryActivity] { throw M5RepositoryError.unexpectedCall }
    func fetchNextUpcoming(after date: Date) async throws -> ItineraryActivity? { throw M5RepositoryError.unexpectedCall }
    func add(_ activity: ItineraryActivity) async throws { throw M5RepositoryError.unexpectedCall }
    func update(_ activity: ItineraryActivity) async throws { throw M5RepositoryError.unexpectedCall }
    func delete(id: UUID) async throws { throw M5RepositoryError.unexpectedCall }
}
