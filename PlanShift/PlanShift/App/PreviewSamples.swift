// Module: Shared – tiny sample values for placeholders and previews only.

import Foundation

/// NOT test data: just enough values for placeholder screens and #Previews.
nonisolated enum PreviewSamples {
    static let trip = Trip(name: "Sydney Weekend", startDate: date(day: 13), endDate: date(day: 15))

    static let coastalWalk = ItineraryActivity(
        tripId: trip.id, name: "Bondi to Coogee Coastal Walk", date: date(day: 14),
        startTime: date(day: 14, hour: 9), endTime: date(day: 14, hour: 12),
        locationName: "Bondi Beach", latitude: -33.8915, longitude: 151.2767,
        setting: .outdoor, estimatedCost: 0
    )

    static let tarongaZoo = ItineraryActivity(
        tripId: trip.id, name: "Taronga Zoo", date: date(day: 14),
        startTime: date(day: 14, hour: 13, minute: 30), endTime: date(day: 14, hour: 16, minute: 30),
        locationName: "Mosman", latitude: -33.8435, longitude: 151.2413,
        setting: .outdoor, estimatedCost: 51
    )

    static let australianMuseum = Place(
        name: "Australian Museum", suburb: "Sydney", setting: .indoor, cost: 0,
        durationMinutes: 120, latitude: -33.8743, longitude: 151.2132,
        openingHour: 10, closingHour: 17, imageName: "australian-museum",
        suitableDisruptions: [.rainyWeather, .attractionClosed]
    )

    static let queenVictoriaBuilding = Place(
        name: "Queen Victoria Building", suburb: "Sydney", setting: .indoor, cost: 0,
        durationMinutes: 60, latitude: -33.8718, longitude: 151.2067,
        openingHour: 9, closingHour: 18, imageName: "queen-victoria-building",
        suitableDisruptions: [.rainyWeather, .runningOutOfTime]
    )

    static let activities = [coastalWalk, tarongaZoo]
    static let places = [australianMuseum, queenVictoriaBuilding]

    /// A date in November 2026, e.g. `date(day: 14, hour: 9)`.
    static func date(day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        let components = DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute)
        return Calendar.current.date(from: components) ?? .now
    }
}
