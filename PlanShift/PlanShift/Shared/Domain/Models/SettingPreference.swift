// Module: Shared – domain model.

import Foundation

/// Indoor/outdoor filter on M2-02 ("any" = no preference).
nonisolated enum SettingPreference: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case indoor
    case outdoor
    case any

    var id: String { rawValue }

    var title: String {
        switch self {
        case .indoor: "Indoor"
        case .outdoor: "Outdoor"
        case .any: "Any"
        }
    }
}
