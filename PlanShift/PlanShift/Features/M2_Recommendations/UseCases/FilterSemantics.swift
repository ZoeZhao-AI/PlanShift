//
//  FilterSemantics.swift
//  PlanShift
//
//  Created by Van Dao Le on 15/10/2026.
//

// Module: M2 – what each M2-02 filter chip means, in numbers.

import Foundation

nonisolated extension BudgetOption {
    /// `true` if a place with this entry price passes the filter. Price is in AUD.
    func allows(cost: Decimal) -> Bool {
        switch self {
        case .free: cost == 0
        case .under30: cost < 30
        case .any: true
        }
    }
}

nonisolated extension DistanceOption {
    /// Hard distance limit in metres; `nil` = no limit ("5 km+").
    var limitMeters: Double? {
        switch self {
        case .oneKm: 1_000
        case .threeKm: 3_000
        case .fiveKmPlus: nil
        }
    }
}

nonisolated extension DurationOption {
    /// Visit-length bucket in minutes. Buckets do not overlap:
    /// under 1 hr = up to 60, 1–2 hrs = 61–120, half day = over 120.
    func allows(minutes: Int) -> Bool {
        switch self {
        case .underOneHour: minutes <= 60
        case .oneToTwoHours: minutes > 60 && minutes <= 120
        case .halfDay: minutes > 120
        }
    }
}

nonisolated extension SettingPreference {
    func allows(_ setting: ActivitySetting) -> Bool {
        switch self {
        case .indoor: setting == .indoor
        case .outdoor: setting == .outdoor
        case .any: true
        }
    }
}
