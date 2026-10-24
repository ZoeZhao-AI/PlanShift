import XCTest
@testable import PlanShift

final class ResolveWidgetActivityLinkTests: XCTestCase {
    private let tripId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    func testReturnsLinkedActivityRatherThanFirstActivity() async throws {
        let expected = activity(name: "Museum")
        let repository = WidgetLinkActivitiesStub(items: [activity(name: "Zoo"), expected])
        let result = try await ResolveWidgetActivityLink(repository: repository)
            .execute(url: link(to: expected), tripId: tripId)

        XCTAssertEqual(result, expected)
        let requestedTrips = await repository.requestedTripIds
        XCTAssertEqual(requestedTrips, [tripId])
    }

    func testInvalidLinksReturnNilWithoutReadingRepository() async throws {
        let id = UUID().uuidString
        let urls = ["https://activity/\(id)", "planshift://activity/not-an-id",
                    "planshift://activity/\(id)/extra", "planshift://activity/\(id)?other=true"]
        let repository = WidgetLinkActivitiesStub(error: DomainError.persistenceFailure)
        let resolver = ResolveWidgetActivityLink(repository: repository)

        for text in urls {
            let result = try await resolver.execute(url: XCTUnwrap(URL(string: text)), tripId: tripId)
            XCTAssertNil(result)
        }
        let requestedTrips = await repository.requestedTripIds
        XCTAssertTrue(requestedTrips.isEmpty)
    }

    func testDeletedActivityDoesNotFallBackToAnotherActivity() async throws {
        let deleted = activity(name: "Deleted museum")
        let repository = MockActivityRepository(activities: [deleted, activity(name: "Other activity")])
        let resolver = ResolveWidgetActivityLink(repository: repository)
        let url = try link(to: deleted)
        let original = try await resolver.execute(url: url, tripId: tripId)
        XCTAssertEqual(original, deleted)

        try await repository.delete(id: deleted.id)
        do {
            _ = try await resolver.execute(url: url, tripId: tripId)
            XCTFail("Expected missing activity after deletion")
        } catch {
            XCTAssertEqual(error as? DomainError, .activityNotFound)
        }
    }

    func testMissingActivityInEmptyRepositoryThrowsNotFound() async throws {
        do {
            _ = try await ResolveWidgetActivityLink(repository: MockActivityRepository())
                .execute(url: link(to: activity()), tripId: tripId)
            XCTFail("Expected missing activity")
        } catch {
            XCTAssertEqual(error as? DomainError, .activityNotFound)
        }
    }

    func testActivityFromAnotherTripIsNotReturned() async throws {
        var otherTrip = activity()
        otherTrip.tripId = UUID()
        // Deliberately return an out-of-scope item to verify the trip check.
        let repository = WidgetLinkActivitiesStub(items: [otherTrip])
        do {
            _ = try await ResolveWidgetActivityLink(repository: repository)
                .execute(url: link(to: otherTrip), tripId: tripId)
            XCTFail("Expected no match in the supplied trip")
        } catch {
            XCTAssertEqual(error as? DomainError, .activityNotFound)
        }
    }

    func testReadsLatestStoredValuesEvenWhenActivityHasAlreadyEnded() async throws {
        let original = activity(name: "Old name")
        let repository = MockActivityRepository(activities: [original])
        var updated = original
        updated.name = "Updated museum"
        try await repository.update(updated)

        let result = try await ResolveWidgetActivityLink(repository: repository)
            .execute(url: link(to: original), tripId: tripId)
        XCTAssertEqual(result, updated)
    }

    func testRepositoryDomainErrorsArePreserved() async throws {
        for expected in [DomainError.persistenceFailure, .activityNotFound] {
            let repository = WidgetLinkActivitiesStub(error: expected)
            do {
                _ = try await ResolveWidgetActivityLink(repository: repository)
                    .execute(url: link(to: activity()), tripId: tripId)
                XCTFail("Expected repository failure")
            } catch {
                XCTAssertEqual(error as? DomainError, expected)
            }
        }
    }

    func testUnexpectedReadErrorMapsToPersistenceFailure() async throws {
        let repository = WidgetLinkActivitiesStub(error: WidgetLinkReadError.unavailable)
        do {
            _ = try await ResolveWidgetActivityLink(repository: repository)
                .execute(url: link(to: activity()), tripId: tripId)
            XCTFail("Expected read failure, not a missing activity")
        } catch {
            XCTAssertEqual(error as? DomainError, .persistenceFailure)
        }
    }

    func testRepositoryCancellationIsPreserved() async throws {
        let repository = WidgetLinkActivitiesStub(error: CancellationError())
        do {
            _ = try await ResolveWidgetActivityLink(repository: repository)
                .execute(url: link(to: activity()), tripId: tripId)
            XCTFail("Expected cancellation")
        } catch {
            XCTAssertTrue(error is CancellationError)
        }
    }

    private func link(to activity: ItineraryActivity) throws -> URL {
        try XCTUnwrap(WidgetActivityLink.url(for: activity.id))
    }

    private func activity(name: String = "Museum") -> ItineraryActivity {
        let date = Date(timeIntervalSince1970: 946_684_800)
        return ItineraryActivity(tripId: tripId, name: name, date: date,
                                 startTime: date, endTime: date.addingTimeInterval(3600),
                                 locationName: "Sydney", latitude: -33.87, longitude: 151.21,
                                 setting: .indoor, estimatedCost: 0)
    }
}

private nonisolated enum WidgetLinkReadError: Error { case unavailable, unexpectedCall }

private actor WidgetLinkActivitiesStub: ActivityRepository {
    private let items: [ItineraryActivity]
    private let error: (any Error)?
    private(set) var requestedTripIds: [UUID] = []

    init(items: [ItineraryActivity] = [], error: (any Error)? = nil) {
        self.items = items
        self.error = error
    }

    func fetchActivities(tripId: UUID) async throws -> [ItineraryActivity] {
        requestedTripIds.append(tripId)
        if let error { throw error }
        return items
    }
    func fetchActivities(on date: Date) async throws -> [ItineraryActivity] { throw WidgetLinkReadError.unexpectedCall }
    func fetchNextUpcoming(after date: Date) async throws -> ItineraryActivity? { throw WidgetLinkReadError.unexpectedCall }
    func add(_ activity: ItineraryActivity) async throws { throw WidgetLinkReadError.unexpectedCall }
    func update(_ activity: ItineraryActivity) async throws { throw WidgetLinkReadError.unexpectedCall }
    func delete(id: UUID) async throws { throw WidgetLinkReadError.unexpectedCall }
}
