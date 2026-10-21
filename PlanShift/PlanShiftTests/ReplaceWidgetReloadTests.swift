//
//  ReplaceWidgetReloadTests.swift
//  PlanShiftTests
//
//  Created by Chang Chia ming on 2026/10/21.
//

import XCTest
@testable import PlanShift

final class ReplaceWidgetReloadTests: XCTestCase {
    @MainActor
    func testSuccessfulReplaceAndUndoEachRequestReload() async {
        let original = PreviewSamples.coastalWalk
        let activities = MockActivityRepository(activities: [original])
        var requestedKinds: [String] = []

        let model = makeModel(
            activities: activities,
            reloader: WidgetTimelineReloader {
                requestedKinds.append($0)
            }
        )

        XCTAssertTrue(requestedKinds.isEmpty)

        let confirmed = await model.confirm(
            activity: original,
            alternative: PreviewSamples.australianMuseum
        )

        XCTAssertTrue(confirmed)
        XCTAssertEqual(requestedKinds, ["PlanShiftWidget"])

        let undone = await model.undo()

        XCTAssertTrue(undone)
        XCTAssertEqual(
            requestedKinds,
            ["PlanShiftWidget", "PlanShiftWidget"]
        )
    }

    @MainActor
    func testFailedReplaceDoesNotRequestReload() async {
        let activities = MockActivityRepository(
            activities: [PreviewSamples.coastalWalk],
            updateError: .persistenceFailure
        )
        var reloadCount = 0

        let model = makeModel(
            activities: activities,
            reloader: WidgetTimelineReloader { _ in
                reloadCount += 1
            }
        )

        let confirmed = await model.confirm(
            activity: PreviewSamples.coastalWalk,
            alternative: PreviewSamples.australianMuseum
        )

        XCTAssertFalse(confirmed)
        XCTAssertNotNil(model.errorMessage)
        XCTAssertEqual(reloadCount, 0)
    }

    @MainActor
    func testFailedUndoDoesNotRequestAnotherReload() async throws {
        let original = PreviewSamples.coastalWalk
        let activities = MockActivityRepository(activities: [original])
        var reloadCount = 0

        let model = makeModel(
            activities: activities,
            reloader: WidgetTimelineReloader { _ in
                reloadCount += 1
            }
        )

        let confirmed = await model.confirm(
            activity: original,
            alternative: PreviewSamples.australianMuseum
        )

        XCTAssertTrue(confirmed)
        XCTAssertEqual(reloadCount, 1)

        try await activities.delete(id: original.id)

        let undone = await model.undo()

        XCTAssertFalse(undone)
        XCTAssertTrue(model.canUndo)
        XCTAssertNotNil(model.errorMessage)
        XCTAssertEqual(reloadCount, 1)
    }

    @MainActor
    func testIgnoredActionsDoNotRequestReload() async {
        let original = PreviewSamples.coastalWalk
        let activities = MockActivityRepository(activities: [original])
        var reloadCount = 0

        let model = makeModel(
            activities: activities,
            reloader: WidgetTimelineReloader { _ in
                reloadCount += 1
            }
        )

        let initialUndo = await model.undo()
        XCTAssertFalse(initialUndo)
        XCTAssertEqual(reloadCount, 0)

        let confirmed = await model.confirm(
            activity: original,
            alternative: PreviewSamples.australianMuseum
        )
        XCTAssertTrue(confirmed)
        XCTAssertEqual(reloadCount, 1)

        let repeatedConfirm = await model.confirm(
            activity: original,
            alternative: PreviewSamples.australianMuseum
        )
        XCTAssertFalse(repeatedConfirm)
        XCTAssertEqual(reloadCount, 1)

        model.dismissSuccess()
        XCTAssertEqual(reloadCount, 1)

        let dismissedUndo = await model.undo()
        XCTAssertFalse(dismissedUndo)
        XCTAssertEqual(reloadCount, 1)
    }

    @MainActor
    private func makeModel(
        activities: MockActivityRepository,
        reloader: WidgetTimelineReloader
    ) -> ReplaceViewModel {
        ReplaceViewModel(
            replaceActivity: ReplaceActivityUseCase(
                activityRepository: activities,
                backupRepository: MockBackupRepository()
            ),
            undoReplace: UndoReplaceUseCase(
                activityRepository: activities
            ),
            widgetReloader: reloader
        )
    }
}
