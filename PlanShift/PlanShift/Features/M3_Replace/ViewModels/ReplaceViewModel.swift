//
//  ReplaceViewModel.swift
//  PlanShift
//
//  Created by Chang Chia ming on 2026/10/16.
//

import Foundation
import Observation

@MainActor
@Observable
final class ReplaceViewModel {
    private(set) var isProcessing = false
    private(set) var errorMessage: String?
    private(set) var originalActivity: ItineraryActivity?
    private(set) var replacementName: String?

    private let replaceActivity: ReplaceActivityUseCase
    private let undoReplace: UndoReplaceUseCase
    private let widgetReloader: WidgetTimelineReloader

    var canUndo: Bool {
        originalActivity != nil
    }

    init(
        replaceActivity: ReplaceActivityUseCase,
        undoReplace: UndoReplaceUseCase,
        widgetReloader: WidgetTimelineReloader? = nil
    ) {
        self.replaceActivity = replaceActivity
        self.undoReplace = undoReplace
        self.widgetReloader = widgetReloader ?? WidgetTimelineReloader()
    }

    func confirm(
        activity: ItineraryActivity,
        alternative: Place
    ) async -> Bool {
        guard !isProcessing, !canUndo else {
            return false
        }

        isProcessing = true
        errorMessage = nil
        defer { isProcessing = false }

        do {
            let original = try await replaceActivity.execute(
                activity: activity,
                with: alternative
            )

            originalActivity = original
            replacementName = alternative.name
            widgetReloader.requestReload()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func undo() async -> Bool {
        guard !isProcessing,
              let originalActivity else {
            return false
        }

        isProcessing = true
        errorMessage = nil
        defer { isProcessing = false }

        do {
            try await undoReplace.execute(
                originalActivity: originalActivity
            )

            self.originalActivity = nil
            replacementName = nil
            widgetReloader.requestReload()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func dismissSuccess() {
        guard !isProcessing else {
            return
        }

        originalActivity = nil
        replacementName = nil
    }

    func clearError() {
        errorMessage = nil
    }
    
    func proposedEndTime(
        for activity: ItineraryActivity,
        alternative: Place
    ) -> Date? {
        guard alternative.durationMinutes > 0 else {
            return nil
        }

        return activity.startTime.addingTimeInterval(
            TimeInterval(alternative.durationMinutes) * 60
        )
    }
}
