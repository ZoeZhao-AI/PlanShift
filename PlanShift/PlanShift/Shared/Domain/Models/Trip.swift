// Module: Shared – domain model.

import Foundation

/// A trip the traveller is planning, e.g. "Sydney Weekend".
/// Domain models are plain Sendable structs: no SwiftUI, no Core Data.
/// `nonisolated` lets them be used from any thread and in any target (app, widget, tests).
nonisolated struct Trip: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    var name: String
    var startDate: Date
    var endDate: Date

    init(id: UUID = UUID(), name: String, startDate: Date, endDate: Date) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
    }

    /// Number of calendar days in the trip, counting the first and last day.
    /// Returns 0 if the end date is before the start date.
    var dayCount: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        let daysBetween = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        return max(daysBetween + 1, 0)
    }

    /// One date (at midnight) for each day of the trip, in order.
    var dayDates: [Date] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        return (0..<dayCount).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }
}
