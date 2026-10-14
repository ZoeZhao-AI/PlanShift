// Module: Shared – domain model.

import Foundation

/// The quick filters the traveller adjusts before seeing alternatives (M2-02).
nonisolated struct PreferenceFilters: Hashable, Codable, Sendable {
    var budget: BudgetOption = .any
    var maxDistance: DistanceOption = .threeKm
    var duration: DurationOption = .oneToTwoHours
    var setting: SettingPreference = .any
}
