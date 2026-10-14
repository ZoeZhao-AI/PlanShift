// Module: Shared – domain model.

import Foundation

/// One planned activity in the itinerary, e.g. "Taronga Zoo, 1:30–4:30 pm".
nonisolated struct ItineraryActivity: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    var tripId: UUID
    var name: String
    /// The day of the activity.
    var date: Date
    /// Full date and time the activity starts.
    var startTime: Date
    /// Full date and time the activity ends (must be after `startTime`).
    var endTime: Date
    var locationName: String
    var latitude: Double
    var longitude: Double
    var setting: ActivitySetting
    /// Estimated cost in AUD.
    var estimatedCost: Decimal

    init(
        id: UUID = UUID(),
        tripId: UUID,
        name: String,
        date: Date,
        startTime: Date,
        endTime: Date,
        locationName: String,
        latitude: Double,
        longitude: Double,
        setting: ActivitySetting,
        estimatedCost: Decimal
    ) {
        self.id = id
        self.tripId = tripId
        self.name = name
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.locationName = locationName
        self.latitude = latitude
        self.longitude = longitude
        self.setting = setting
        self.estimatedCost = estimatedCost
    }
}
