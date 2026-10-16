//
//  UndoReplaceUseCase.swift
//  PlanShift
//
//  Created by Chang Chia ming on 2026/10/15.
//

import Foundation

nonisolated struct UndoReplaceUseCase: Sendable {
    private let activityRepository: any ActivityRepository

    init(activityRepository: any ActivityRepository) {
        self.activityRepository = activityRepository
    }

    func execute(
        originalActivity: ItineraryActivity
    ) async throws {
        try await activityRepository.update(originalActivity)
    }
}
