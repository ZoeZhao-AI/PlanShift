// Module: Shared – domain model.

import Foundation

/// A short reason why an alternative was recommended (M2-03).
nonisolated enum ReasonTag: Hashable, Codable, Identifiable, Sendable {
    case indoors
    case withinBudget
    case free
    case walkingMinutes(Int)
    case underTwoHours
    case openNow

    /// Stable id so tags can be used in a SwiftUI ForEach.
    var id: String { displayText }

    var displayText: String {
        switch self {
        case .indoors: "Indoors"
        case .withinBudget: "Within budget"
        case .free: "Free"
        case .walkingMinutes(let minutes): "\(minutes) min walk"
        case .underTwoHours: "Under 2 hours"
        case .openNow: "Open now"
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
        }
    }
}
