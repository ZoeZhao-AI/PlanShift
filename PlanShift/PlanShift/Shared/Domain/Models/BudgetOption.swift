// Module: Shared – domain model.

import Foundation

/// Budget filter on M2-02.
nonisolated enum BudgetOption: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case free
    case under30
    case any

    var id: String { rawValue }

    var title: String {
        switch self {
        case .free: "Free"
        case .under30: "Under $30"
        case .any: "Any"
        }
    }
}
