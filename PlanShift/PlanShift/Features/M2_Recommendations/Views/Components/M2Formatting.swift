//
//  M2Formatting.swift
//  PlanShift
//
//  Created by Van Dao Le on 15/10/2026.
//

// Module: M2 – text formatting and small UI mappings for M2 screens.

import Foundation

nonisolated enum M2Formatting {
    /// "Free" or "$57". Costs are whole AUD in the dataset.
    static func cost(_ amount: Decimal) -> String {
        amount == 0 ? "Free" : amount.formatted(.currency(code: "AUD").precision(.fractionLength(0)))
    }

    /// Visit length, e.g. "~45 min", "~1.5 hrs", "~2 hrs".
    static func duration(minutes: Int) -> String {
        if minutes < 60 { return "~\(minutes) min" }
        let hours = Double(minutes) / 60
        let text = hours.rounded() == hours ? String(Int(hours)) : String(format: "%.1f", hours)
        return hours <= 1 ? "~1 hr" : "~\(text) hrs"
    }

    /// Straight-line distance, e.g. "1.8 km" or "450 m". The results screen footnote says it is approximate.
    static func distance(meters: Double) -> String {
        // 995–999 m would round to "1000 m", so switch to km from 995 m.
        meters < 995 ? "\(Int((meters / 10).rounded() * 10)) m" : String(format: "%.1f km", meters / 1_000)
    }

    /// 24-hour clock like the design: "12:30 – 15:30".
    static func timeRange(of activity: ItineraryActivity, calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        return "\(formatter.string(from: activity.startTime)) – \(formatter.string(from: activity.endTime))"
    }

    /// "Day 1" when the trip is known, otherwise the date, e.g. "Sat 14 Nov".
    static func dayLabel(for activity: ItineraryActivity, tripStart: Date?, calendar: Calendar = .current) -> String {
        if let tripStart {
            let start = calendar.startOfDay(for: tripStart)
            let day = calendar.startOfDay(for: activity.date)
            if let offset = calendar.dateComponents([.day], from: start, to: day).day, offset >= 0 {
                return "Day \(offset + 1)"
            }
        }
        return activity.date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
    }

    /// Short filter summary, e.g. ["Indoor", "Under $30", "≤ 3 km", "1–2 hrs"]. Only narrowed filters are listed.
    /// `withinStyle` writes distances as "Within 1 km" (used on the no-results screen).
    static func summary(of filters: PreferenceFilters, withinStyle: Bool = false) -> [String] {
        var items: [String] = []
        if filters.setting != .any { items.append(filters.setting.title) }
        if filters.budget != .any { items.append(filters.budget.title) }
        switch filters.maxDistance {
        case .oneKm: items.append(withinStyle ? "Within 1 km" : "≤ 1 km")
        case .threeKm: items.append(withinStyle ? "Within 3 km" : "≤ 3 km")
        case .fiveKmPlus: items.append("5 km+")
        }
        items.append(filters.duration.title)
        return items
    }

    /// "Nothing outdoors within 1 km is free for half a day." – built from the actual filters.
    static func noResultsSentence(for filters: PreferenceFilters) -> String {
        var subject = "Nothing"
        switch filters.setting {
        case .indoor: subject += " indoors"
        case .outdoor: subject += " outdoors"
        case .any: break
        }
        switch filters.maxDistance {
        case .oneKm: subject += " within 1 km"
        case .threeKm: subject += " within 3 km"
        case .fiveKmPlus: break
        }
        let duration: String
        switch filters.duration {
        case .underOneHour: duration = "under an hour"
        case .oneToTwoHours: duration = "1–2 hours"
        case .halfDay: duration = "half a day"
        }
        switch filters.budget {
        case .free: return "\(subject) is free for \(duration)."
        case .under30: return "\(subject) is under $30 for \(duration)."
        case .any: return "\(subject) takes \(duration)."
        }
    }

    /// Slug used to find a place's image in the asset catalog from an activity name ("Taronga Zoo" → "taronga-zoo").
    static func imageSlug(for name: String) -> String {
        name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
    }
}
