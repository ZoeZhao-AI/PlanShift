//
//  BackupSaving.swift
//  PlanShift
//
//  Created by Van Dao Le on 15/10/2026.
//

// Module: M2 – the interface M2-03's bookmark button calls. The implementation belongs to M4.

import Foundation

/// What M2 needs from Backups. M2 only *initiates* the save; M4 owns persistence and the duplicate rule.
nonisolated protocol BackupSaving: Sendable {
    func isSaved(placeId: UUID, tripId: UUID) async throws -> Bool
    /// Saves `place` as a backup of the activity's trip and day.
    /// - Throws: `DomainError.duplicateBackup` if this trip already has it.
    func save(place: Place, for activity: ItineraryActivity) async throws
}
