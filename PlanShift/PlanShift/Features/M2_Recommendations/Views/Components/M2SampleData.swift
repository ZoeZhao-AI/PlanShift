//
//  M2SampleData.swift
//  PlanShift
//
//  Created by Van Dao Le on 15/10/2026.
//

// Module: M2 – fixed sample content so the screens show something real-looking before any logic is wired in.
// This is UI-only data (the design's examples): it never touches the ranker, the dataset or any repository.

import Foundation

enum M2SampleData {
    /// "Taronga Zoo, 12:30–15:30" – the affected activity in the design.
    static let activity = ItineraryActivity(
        tripId: PreviewSamples.trip.id, name: "Taronga Zoo", date: PreviewSamples.date(day: 14),
        startTime: PreviewSamples.date(day: 14, hour: 12, minute: 30), endTime: PreviewSamples.date(day: 14, hour: 15, minute: 30),
        locationName: "Mosman", latitude: -33.8435, longitude: 151.2413, setting: .outdoor, estimatedCost: 51
    )

    static let artGallery = Place(
        name: "Art Gallery of NSW", suburb: "The Domain", setting: .indoor, cost: 0,
        durationMinutes: 90, latitude: -33.8686, longitude: 151.2174,
        openingHour: 10, closingHour: 17, imageName: "art-gallery-of-nsw",
        suitableDisruptions: [.rainyWeather, .attractionClosed]
    )

    /// Three ranked alternatives, as in the design's M2-03.
    static let alternatives: [RankedAlternative] = [
        RankedAlternative(rank: 1, place: PreviewSamples.australianMuseum, distanceMeters: 1_800, walkingMinutes: 22,
                          reasons: [.indoors, .withinBudget, .walkingMinutes(22)], score: 0.9),
        RankedAlternative(rank: 2, place: artGallery, distanceMeters: 1_400, walkingMinutes: 18,
                          reasons: [.indoors, .walkingMinutes(18)], score: 0.8),
        RankedAlternative(rank: 3, place: PreviewSamples.queenVictoriaBuilding, distanceMeters: 1_300, walkingMinutes: 16,
                          reasons: [.indoors, .underTwoHours], score: 0.7),
    ]

    /// Filters shown on M2-02 for the design's rainy-day example.
    static let rainyFilters = PreferenceFilters(budget: .under30, maxDistance: .threeKm, duration: .oneToTwoHours, setting: .indoor)

    /// Filters that match nothing, for the M2-04 example.
    static let noMatchFilters = PreferenceFilters(budget: .free, maxDistance: .oneKm, duration: .halfDay, setting: .outdoor)
}
