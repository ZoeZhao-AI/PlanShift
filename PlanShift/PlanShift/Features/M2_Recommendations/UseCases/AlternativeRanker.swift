//
//  AlternativeRanker.swift
//  PlanShift
//
//  Created by Van Dao Le on 15/10/2026.
//

// Module: M2 – deterministic ranking of replacement places.

import Foundation

/// Pure, I/O-free ranking of local places. Same input → same output, always.
///
/// Pipeline (see `RankingWeights` for the numbers):
/// 1. Drop the original activity's own place.
/// 2. **Hard filters**: budget, setting, duration bucket, distance (only if an origin exists),
///    and places that are closed for the *entire* planned time slot.
/// 3. Score survivors with six components, weighted per disruption.
/// 4. Pick up to 8 greedily, penalising a suburb that is already represented (the screen shows 3 first).
/// 5. Break ties by name, then id. Missing data is never treated as free/zero/open.
///
/// Opening hours are checked against the activity's planned slot, not the wall clock, so the
/// result does not depend on "now". Only the regular daily window is known (no per-weekday data).
nonisolated struct AlternativeRanker: Sendable {
    var calendar: Calendar = .current
    var maxResults = 8

    /// - Throws: `DomainError.noMatchingAlternatives` when nothing survives the hard filters.
    func rank(
        places: [Place],
        activity: ItineraryActivity,
        disruption: Disruption,
        filters: PreferenceFilters,
        origin: ResolvedOrigin
    ) throws -> [RankedAlternative] {
        let candidates = scoredCandidates(places, activity: activity, disruption: disruption, filters: filters, origin: origin)
        guard !candidates.isEmpty else { throw DomainError.noMatchingAlternatives }

        return pickTop(from: candidates, diversityPenalty: disruption.rankingWeights.diversityPenalty)
            .enumerated()
            .map { index, candidate in
                RankedAlternative(
                    rank: index + 1,
                    place: candidate.place,
                    distanceMeters: candidate.distance,
                    walkingMinutes: candidate.distance.map(DistanceEstimator.walkingMinutes(forMeters:)),
                    reasons: reasons(for: candidate, activity: activity, disruption: disruption, filters: filters),
                    score: Self.round(candidate.score)
                )
            }
    }

    /// Applies the hard filters, then scores every place that survives.
    private func scoredCandidates(
        _ places: [Place],
        activity: ItineraryActivity,
        disruption: Disruption,
        filters: PreferenceFilters,
        origin: ResolvedOrigin
    ) -> [Candidate] {
        let weights = disruption.rankingWeights
        let slotMinutes = max(1, Int(activity.endTime.timeIntervalSince(activity.startTime) / 60))
        let originalNames = [activity.name, activity.locationName].map(Self.normalize)

        return places.compactMap { place in
            guard !originalNames.contains(Self.normalize(place.name)),
                  filters.budget.allows(cost: place.cost),
                  filters.setting.allows(place.setting),
                  filters.duration.allows(minutes: place.durationMinutes) else { return nil }

            var distance: Double?
            if let originCoordinate = origin.coordinate {
                let meters = DistanceEstimator.meters(from: originCoordinate, to: GeoCoordinate(place))
                if let limit = filters.maxDistance.limitMeters, meters > limit { return nil }
                distance = meters
            }

            let hours = hoursFit(for: place, activity: activity)
            guard hours != .closed else { return nil }

            // c: the place's score on each component (0...1); S = w · c.
            let components = ComponentScores(
                disruptionFit: place.suitableDisruptions.contains(disruption) ? 1 : 0,
                settingFit: settingScore(place, activity: activity, disruption: disruption),
                distance: distanceScore(distance, filters: filters),
                duration: durationScore(place, slotMinutes: slotMinutes, disruption: disruption),
                budget: budgetScore(place, filters: filters),
                hours: hours.score
            )
            return Candidate(place: place, distance: distance, hours: hours, score: weights.score(components))
        }
    }

    /// Picks the best candidate repeatedly, penalising a suburb that is already represented.
    /// Ties are broken by name, then id.
    private func pickTop(from candidates: [Candidate], diversityPenalty: Double) -> [Candidate] {
        var remaining = candidates
        var chosen: [Candidate] = []
        var usedSuburbs = Set<String>()

        func adjustedScore(_ candidate: Candidate) -> Double {
            Self.round(candidate.score - (usedSuburbs.contains(candidate.place.suburb) ? diversityPenalty : 0))
        }

        while chosen.count < maxResults, !remaining.isEmpty {
            let bestIndex = remaining.indices.min { lhs, rhs in
                let (l, r) = (remaining[lhs], remaining[rhs])
                if adjustedScore(l) != adjustedScore(r) { return adjustedScore(l) > adjustedScore(r) }
                if l.place.name != r.place.name { return l.place.name < r.place.name }
                return l.place.id.uuidString < r.place.id.uuidString
            }!
            let pick = remaining.remove(at: bestIndex)
            usedSuburbs.insert(pick.place.suburb)
            chosen.append(pick)
        }
        return chosen
    }

    // MARK: - Scoring components (each 0...1)

    private struct Candidate {
        let place: Place
        let distance: Double?
        let hours: HoursFit
        let score: Double
    }

    private enum HoursFit {
        case unrestricted, fullyOpen, partial, closed

        var score: Double {
            switch self {
            case .fullyOpen: 1
            case .unrestricted: 0.7
            case .partial: 0.4
            case .closed: 0
            }
        }
    }

    private func settingScore(_ place: Place, activity: ItineraryActivity, disruption: Disruption) -> Double {
        if disruption == .rainyWeather { return place.setting == .indoor ? 1 : 0 }
        return place.setting == activity.setting ? 1 : 0.5
    }

    private func distanceScore(_ distance: Double?, filters: PreferenceFilters) -> Double {
        // Unknown distance is neutral, never "0 m" (which would be the best score).
        guard let distance else { return 0.5 }
        let range = filters.maxDistance.limitMeters ?? 10_000
        return Self.clamp(1 - distance / range)
    }

    private func durationScore(_ place: Place, slotMinutes: Int, disruption: Disruption) -> Double {
        if disruption == .runningOutOfTime { return Self.clamp(1 - Double(place.durationMinutes) / 240) }
        let longest = Double(max(place.durationMinutes, slotMinutes))
        return Self.clamp(1 - abs(Double(place.durationMinutes - slotMinutes)) / longest)
    }

    private func budgetScore(_ place: Place, filters: PreferenceFilters) -> Double {
        if place.cost == 0 { return 1 }
        let ceiling: Double = filters.budget == .under30 ? 30 : 60
        return Self.clamp(1 - NSDecimalNumber(decimal: place.cost).doubleValue / ceiling)
    }

    private func hoursFit(for place: Place, activity: ItineraryActivity) -> HoursFit {
        // 0–24 marks a public open space with no gated hours.
        if place.openingHour == 0 && place.closingHour == 24 { return .unrestricted }
        let start = minutesOfDay(activity.startTime)
        let end = calendar.isDate(activity.startTime, inSameDayAs: activity.endTime) ? minutesOfDay(activity.endTime) : 1_440
        let open = place.openingHour * 60
        let close = place.closingHour * 60
        if end <= open || start >= close { return .closed }
        if start >= open && start + place.durationMinutes <= close { return .fullyOpen }
        return .partial
    }

    private func minutesOfDay(_ date: Date) -> Int {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        return (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
    }

    // MARK: - Reason tags (computed from the candidate's real values)

    private func reasons(
        for candidate: Candidate,
        activity: ItineraryActivity,
        disruption: Disruption,
        filters: PreferenceFilters
    ) -> [ReasonTag] {
        let place = candidate.place
        var tags: [ReasonTag] = []
        if place.setting == .indoor && (disruption == .rainyWeather || filters.setting == .indoor) {
            tags.append(.indoors)
        }
        if filters.budget != .any {
            tags.append(.withinBudget)
        } else if place.cost == 0 {
            tags.append(.free)
        }
        if let distance = candidate.distance {
            let minutes = DistanceEstimator.walkingMinutes(forMeters: distance)
            if disruption == .transportDelay { tags.append(.closeBy) }
            if minutes <= 30 { tags.append(.walkingMinutes(minutes)) }
        }
        if disruption == .runningOutOfTime && place.durationMinutes <= 60 {
            tags.append(.quickVisit)
        } else if place.durationMinutes <= 120 {
            tags.append(.underTwoHours)
        }
        if candidate.hours == .fullyOpen { tags.append(.openDuringSlot) }
        if disruption == .attractionClosed && place.setting == activity.setting { tags.append(.similarSetting) }
        return Array(tags.prefix(4))
    }

    // MARK: - Helpers

    private static func clamp(_ value: Double) -> Double { min(1, max(0, value)) }
    /// Rounds away floating-point noise so ties are resolved by name/id, not by 1e-16 differences.
    private static func round(_ value: Double) -> Double { (value * 1_000_000).rounded() / 1_000_000 }

    private static func normalize(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
            .filter { $0.isLetter || $0.isNumber }
    }
}
