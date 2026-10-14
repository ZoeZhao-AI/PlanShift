// Module: Shared – domain model.

import Foundation

/// Maximum distance filter on M2-02.
nonisolated enum DistanceOption: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case oneKm
    case threeKm
    case fiveKmPlus

    var id: String { rawValue }

    var title: String {
        switch self {
        case .oneKm: "1 km"
        case .threeKm: "3 km"
        case .fiveKmPlus: "5 km+"
        }
    }
}
