//
//  ReasonTag.swift
//  PlanShift
//
//  Created by Van Dao Le on 15/10/2026.
//

// Module: Shared – domain model.

import Foundation

/// A short reason why an alternative was recommended (M2-03).
/// Every tag is computed from real data by `AlternativeRanker`; none is static copy.
nonisolated enum ReasonTag: Hashable, Codable, Identifiable, Sendable {
    case indoors
    case withinBudget
    case free
    /// Estimated, not routed. Shown with a "~".
    case walkingMinutes(Int)
    case underTwoHours
    /// Kept for compatibility; the ranker uses `openDuringSlot` because "now" is not the planned time.
    case openNow
    /// The place is open for the whole visit if started at the planned time.
    case openDuringSlot
    case quickVisit
    case closeBy
    case similarSetting

    /// Stable id so tags can be used in a SwiftUI ForEach.
    var id: String { displayText }

    var displayText: String {
        switch self {
        case .indoors: "Indoors"
        case .withinBudget: "Within budget"
        case .free: "Free"
        case .walkingMinutes(let minutes): "~\(minutes) min walk"
        case .underTwoHours: "Under 2 hours"
        case .openNow: "Open now"
        case .openDuringSlot: "Open at that time"
        case .quickVisit: "Quick visit"
        case .closeBy: "Close by"
        case .similarSetting: "Similar setting"
        }
    }

    /// SF Symbol name.
    var symbolName: String {
        switch self {
        case .indoors: "umbrella.fill"
        case .withinBudget: "dollarsign.circle"
        case .free: "gift"
        case .walkingMinutes: "figure.walk"
        case .underTwoHours: "clock"
        case .openNow: "door.left.hand.open"
        case .openDuringSlot: "clock.badge.checkmark"
        case .quickVisit: "hourglass"
        case .closeBy: "location"
        case .similarSetting: "equal.circle"
        }
    }

    /// VoiceOver text; spells out that the walking time is an estimate.
    var accessibilityText: String {
        switch self {
        case .walkingMinutes(let minutes): "About \(minutes) minute walk, estimated"
        default: displayText
        }
    }
}
