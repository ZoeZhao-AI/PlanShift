import XCTest
@testable import PlanShift

final class WidgetTimelineReloaderTests: XCTestCase {
    @MainActor
    func testReloadFollowsCompletedSaveAndReturnsItsResult() async throws {
        var events: [String] = []
        let reloader = WidgetTimelineReloader { kind in events.append("reload:\(kind)") }
        XCTAssertTrue(events.isEmpty)

        let savedID = UUID()
        let result = await reloader.afterSuccessfulChange {
            events.append("saving")
            await Task.yield()
            events.append("saved")
            return savedID
        }

        XCTAssertEqual(result, savedID)
        XCTAssertEqual(events, ["saving", "saved", "reload:PlanShiftWidget"])
    }

    @MainActor
    func testFailedSavePreservesErrorWithoutRequestingReload() async {
        var requestedKinds: [String] = []
        let reloader = WidgetTimelineReloader { requestedKinds.append($0) }
        do {
            try await reloader.afterSuccessfulChange {
                throw DomainError.persistenceFailure
            }
            XCTFail("Expected save failure")
        } catch {
            XCTAssertEqual(error as? DomainError, .persistenceFailure)
        }
        XCTAssertTrue(requestedKinds.isEmpty)
    }

    @MainActor
    func testCancelledSaveDoesNotRequestReload() async {
        var requestedKinds: [String] = []
        let reloader = WidgetTimelineReloader { requestedKinds.append($0) }
        do {
            try await reloader.afterSuccessfulChange {
                throw CancellationError()
            }
            XCTFail("Expected cancellation")
        } catch {
            XCTAssertTrue(error is CancellationError)
        }
        XCTAssertTrue(requestedKinds.isEmpty)
    }

    @MainActor
    func testEachCompletedChangeRequestsReloadWithoutDroppingLaterChanges() async {
        var requestedKinds: [String] = []
        let reloader = WidgetTimelineReloader { requestedKinds.append($0) }
        var savedChanges: [String] = []

        await reloader.afterSuccessfulChange { savedChanges.append("itinerary") }
        await reloader.afterSuccessfulChange { savedChanges.append("backup") }

        XCTAssertEqual(savedChanges, ["itinerary", "backup"])
        XCTAssertEqual(requestedKinds, ["PlanShiftWidget", "PlanShiftWidget"])
    }
}
