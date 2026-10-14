// Module: Shared – domain model.

import Foundation

/// Visit length filter on M2-02.
nonisolated enum DurationOption: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case underOneHour
    case oneToTwoHours
    case halfDay

    var id: String { rawValue }

    var title: String {
        switch self {
        case .underOneHour: "Under 1 hr"
        case .oneToTwoHours: "1–2 hrs"
        case .halfDay: "Half day"
        }
    }
}
