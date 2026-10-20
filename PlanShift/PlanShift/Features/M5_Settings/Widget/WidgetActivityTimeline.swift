import Foundation

/// Plain values that the widget provider can convert to WidgetKit timeline entries.
nonisolated struct WidgetActivityTimeline: Equatable, Sendable {
    enum State: Equatable, Sendable {
        case activity(ItineraryActivity)
        case empty
        case unavailable
    }

    struct Entry: Equatable, Sendable {
        let date: Date
        let state: State
    }

    let entries: [Entry]
    /// A requested reload time, not a guarantee that WidgetKit will wake the extension then.
    let reloadAfter: Date

    static func make(activities: [ItineraryActivity], tripId: UUID, now: Date) -> Self {
        let upcoming = activities
            .filter { $0.tripId == tripId && $0.startTime > now }
            .sorted {
                if $0.startTime == $1.startTime { return $0.id.uuidString < $1.id.uuidString }
                return $0.startTime < $1.startTime
            }

        var entries = [Entry(date: now, state: upcoming.first.map(State.activity) ?? .empty)]
        for (index, activity) in upcoming.enumerated() {
            let next = index + 1 < upcoming.count ? upcoming[index + 1] : nil
            // All activities with this start time stop being "upcoming" together.
            guard next?.startTime != activity.startTime else { continue }
            entries.append(Entry(date: activity.startTime, state: next.map(State.activity) ?? .empty))
        }

        // Cache known transitions so advancing to the next activity does not require a reload.
        // Periodic reloads discover edits; successful app writes should also request a reload.
        return Self(entries: entries, reloadAfter: now.addingTimeInterval(upcoming.isEmpty ? 3600 : 1800))
    }

    static func unavailable(now: Date) -> Self {
        Self(entries: [Entry(date: now, state: .unavailable)],
             reloadAfter: now.addingTimeInterval(900))
    }
}
