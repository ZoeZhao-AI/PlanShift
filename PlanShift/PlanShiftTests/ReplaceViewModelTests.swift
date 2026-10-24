//
//  ReplaceViewModelTests.swift
//  PlanShiftTests
//
//  Created by Chang Chia ming on 2026/10/16.
//

import Foundation
import XCTest
@testable import PlanShift

final class ReplaceViewModelTests: XCTestCase {
    @MainActor
    func testInitialState() {
        let repository = MockActivityRepository()
        let viewModel = makeViewModel(repository: repository)

        XCTAssertFalse(viewModel.isProcessing)
        XCTAssertFalse(viewModel.canUndo)
        XCTAssertNil(viewModel.originalActivity)
        XCTAssertNil(viewModel.replacementName)
        XCTAssertNil(viewModel.errorMessage)
    }

    @MainActor
    func testConfirmStoresSuccessState() async throws {
        let original = PreviewSamples.coastalWalk
        let alternative = PreviewSamples.australianMuseum
        let repository = MockActivityRepository(
            activities: [original]
        )
        let backups = MockBackupRepository()
        let viewModel = makeViewModel(
            repository: repository,
            backups: backups
        )

        let succeeded = await viewModel.confirm(
            activity: original,
            alternative: alternative
        )

        XCTAssertTrue(succeeded)
        XCTAssertFalse(viewModel.isProcessing)
        XCTAssertTrue(viewModel.canUndo)
        XCTAssertEqual(viewModel.originalActivity, original)
        XCTAssertEqual(viewModel.replacementName, alternative.name)
        XCTAssertNil(viewModel.errorMessage)

        let stored = try await repository.fetchActivities(
            tripId: original.tripId
        )
        XCTAssertEqual(stored.first?.name, alternative.name)
    }

    @MainActor
    func testConfirmFailureShowsErrorWithoutUndoState() async {
        let original = PreviewSamples.coastalWalk
        let repository = MockActivityRepository(
            activities: [original]
        )
        let backups = MockBackupRepository(
            saveError: .persistenceFailure
        )
        let viewModel = makeViewModel(
            repository: repository,
            backups: backups
        )

        let succeeded = await viewModel.confirm(
            activity: original,
            alternative: PreviewSamples.australianMuseum
        )

        XCTAssertFalse(succeeded)
        XCTAssertFalse(viewModel.isProcessing)
        XCTAssertFalse(viewModel.canUndo)
        XCTAssertNil(viewModel.originalActivity)
        XCTAssertNil(viewModel.replacementName)
        XCTAssertEqual(
            viewModel.errorMessage,
            DomainError.persistenceFailure.localizedDescription
        )
    }

    @MainActor
    func testRepeatedConfirmDoesNotCreateAnotherBackup() async throws {
        let original = PreviewSamples.coastalWalk
        let alternative = PreviewSamples.australianMuseum
        let repository = MockActivityRepository(
            activities: [original]
        )
        let backups = MockBackupRepository()
        let viewModel = makeViewModel(
            repository: repository,
            backups: backups
        )

        let first = await viewModel.confirm(
            activity: original,
            alternative: alternative
        )
        let second = await viewModel.confirm(
            activity: original,
            alternative: alternative
        )

        let storedBackups = try await backups.fetchBackups(
            tripId: original.tripId
        )

        XCTAssertTrue(first)
        XCTAssertFalse(second)
        XCTAssertEqual(storedBackups.count, 1)
        XCTAssertEqual(viewModel.originalActivity, original)
    }

    @MainActor
    func testUndoRestoresActivityAndClearsSuccessState() async throws {
        let original = PreviewSamples.coastalWalk
        let repository = MockActivityRepository(
            activities: [original]
        )
        let viewModel = makeViewModel(repository: repository)

        let confirmed = await viewModel.confirm(
            activity: original,
            alternative: PreviewSamples.australianMuseum
        )
        XCTAssertTrue(confirmed)

        let succeeded = await viewModel.undo()
        let stored = try await repository.fetchActivities(
            tripId: original.tripId
        )

        XCTAssertTrue(succeeded)
        XCTAssertEqual(stored, [original])
        XCTAssertFalse(viewModel.isProcessing)
        XCTAssertFalse(viewModel.canUndo)
        XCTAssertNil(viewModel.originalActivity)
        XCTAssertNil(viewModel.replacementName)
        XCTAssertNil(viewModel.errorMessage)
    }

    @MainActor
    func testUndoFailurePreservesOriginalAndShowsError() async throws {
        let original = PreviewSamples.coastalWalk
        let repository = MockActivityRepository(
            activities: [original]
        )
        let viewModel = makeViewModel(repository: repository)

        let confirmed = await viewModel.confirm(
            activity: original,
            alternative: PreviewSamples.australianMuseum
        )
        XCTAssertTrue(confirmed)

        try await repository.delete(id: original.id)
        let succeeded = await viewModel.undo()

        XCTAssertFalse(succeeded)
        XCTAssertFalse(viewModel.isProcessing)
        XCTAssertTrue(viewModel.canUndo)
        XCTAssertEqual(viewModel.originalActivity, original)
        XCTAssertEqual(
            viewModel.errorMessage,
            DomainError.activityNotFound.localizedDescription
        )
    }

    @MainActor
    func testUndoWithoutReplacementDoesNothing() async {
        let repository = MockActivityRepository()
        let viewModel = makeViewModel(repository: repository)

        let succeeded = await viewModel.undo()

        XCTAssertFalse(succeeded)
        XCTAssertFalse(viewModel.isProcessing)
        XCTAssertFalse(viewModel.canUndo)
        XCTAssertNil(viewModel.errorMessage)
    }

    @MainActor
    func testDismissSuccessClearsUndoWithoutRestoringActivity() async throws {
        let original = PreviewSamples.coastalWalk
        let alternative = PreviewSamples.australianMuseum
        let repository = MockActivityRepository(
            activities: [original]
        )
        let viewModel = makeViewModel(repository: repository)

        let confirmed = await viewModel.confirm(
            activity: original,
            alternative: alternative
        )
        XCTAssertTrue(confirmed)

        viewModel.dismissSuccess()

        let stored = try await repository.fetchActivities(
            tripId: original.tripId
        )

        XCTAssertFalse(viewModel.canUndo)
        XCTAssertNil(viewModel.originalActivity)
        XCTAssertNil(viewModel.replacementName)
        XCTAssertEqual(stored.first?.name, alternative.name)
    }

    @MainActor
    private func makeViewModel(
        repository: MockActivityRepository,
        backups: MockBackupRepository = MockBackupRepository()
    ) -> ReplaceViewModel {
        ReplaceViewModel(
            replaceActivity: ReplaceActivityUseCase(
                activityRepository: repository,
                backupRepository: backups
            ),
            undoReplace: UndoReplaceUseCase(
                activityRepository: repository
            )
        )
    }
}
