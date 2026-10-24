//
//  M2Fixtures.swift
//  PlanShiftTests
//
//  Created by Van Dao Le on 15/10/2026.
//

// Module: M2 tests – deterministic fixtures. No network, no GPS, no real clock.

import Foundation
@testable import PlanShift

enum M2Fixtures {
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Australia/Sydney")!
        return calendar
    }()

    static let tripId = UUID(uuidString: "00000000-0000-0000-0000-0000000000A1")!

    /// 1 km north is roughly 0.009° of latitude.
    static let originLatitude = -33.8435
    static let originLongitude = 151.2413
    static let origin = GeoCoordinate(latitude: originLatitude, longitude: originLongitude)

    static func date(day: Int = 14, hour: Int, minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute))!
    }

    /// "Taronga Zoo", outdoor, 13:30–16:30 (3 h slot).
    static func activity(
        name: String = "Taronga Zoo",
        locationName: String = "Mosman",
        startHour: Int = 13, startMinute: Int = 30, endHour: Int = 16, endMinute: Int = 30,
        latitude: Double = originLatitude, longitude: Double = originLongitude,
        setting: ActivitySetting = .outdoor
    ) -> ItineraryActivity {
        ItineraryActivity(
            tripId: tripId, name: name, date: date(hour: 0),
            startTime: date(hour: startHour, minute: startMinute), endTime: date(hour: endHour, minute: endMinute),
            locationName: locationName, latitude: latitude, longitude: longitude,
            setting: setting, estimatedCost: 51
        )
    }

    /// A place `kmNorth` kilometres north of the origin. Defaults are neutral: free, 90 min, outdoor, open all day.
    static func place(
        _ name: String,
        id: UUID = UUID(),
        suburb: String? = nil,
        setting: ActivitySetting = .outdoor,
        cost: Decimal = 0,
        minutes: Int = 90,
        kmNorth: Double = 0.5,
        open: Int = 0, close: Int = 24,
        disruptions: [Disruption] = Disruption.allCases
    ) -> Place {
        Place(
            id: id, name: name, suburb: suburb ?? name, setting: setting, cost: cost, durationMinutes: minutes,
            latitude: originLatitude + kmNorth * 0.009, longitude: originLongitude,
            openingHour: open, closingHour: close, imageName: "none", suitableDisruptions: disruptions
        )
    }

    static let plannedOrigin = ResolvedOrigin(coordinate: origin, source: .plannedActivity)
    static let noOrigin = ResolvedOrigin(coordinate: nil, source: .unavailable)

    /// Filters that exclude nothing, so a test only narrows what it is about.
    static let open = PreferenceFilters(budget: .any, maxDistance: .fiveKmPlus, duration: .oneToTwoHours, setting: .any)

    static var ranker: AlternativeRanker { AlternativeRanker(calendar: calendar) }
}
