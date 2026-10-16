//
//  RecommendationFlowViewModel+Backup.swift
//  PlanShift
//
//  Created by Van Dao Le on 15/10/2026.
//

// Module: M2 – use case: bookmark an alternative as a backup (M2-03, with the M4-04 duplicate warning).

import Foundation

extension RecommendationFlowViewModel {
    func isSaved(_ alternative: RankedAlternative) -> Bool { savedPlaceIds.contains(alternative.place.id) }
    func isBusy(_ alternative: RankedAlternative) -> Bool { busyPlaceIds.contains(alternative.place.id) }

    /// Which of these alternatives are already saved for this trip (so the bookmark shows filled).
    func savedIds(in alternatives: [RankedAlternative]) async throws -> Set<UUID> {
        var ids = Set<UUID>()
        for alternative in alternatives where try await backups.isSaved(placeId: alternative.place.id, tripId: activity.tripId) {
            ids.insert(alternative.place.id)
        }
        return ids
    }

    /// Bookmark → SaveBackup. A second tap yields the M4-04 duplicate toast, never a second entry.
    func bookmark(_ alternative: RankedAlternative) async {
        let id = alternative.place.id
        guard !busyPlaceIds.contains(id) else { return } // rapid double tap
        busyPlaceIds.insert(id)
        defer { busyPlaceIds.remove(id) }
        do {
            try await backups.save(place: alternative.place, for: activity)
            savedPlaceIds.insert(id)
            toast = ToastMessage(kind: .success, text: "Saved to backups", actionTitle: "View")
        } catch DomainError.duplicateBackup {
            savedPlaceIds.insert(id)
            toast = ToastMessage(kind: .warning, text: "This activity is already in your backups", actionTitle: "View")
        } catch {
            toast = ToastMessage(kind: .error, text: error.localizedDescription, actionTitle: nil)
        }
    }

    func dismissToast() { toast = nil }
}
