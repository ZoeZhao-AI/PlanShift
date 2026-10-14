// Module: Shared – domain model.

import Foundation

/// Whether an activity or place is indoors or outdoors.
nonisolated enum ActivitySetting: String, CaseIterable, Codable, Hashable, Sendable {
    case indoor
    case outdoor

    var title: String {
        switch self {
        case .indoor: "Indoor"
        case .outdoor: "Outdoor"
        }
    }
}
