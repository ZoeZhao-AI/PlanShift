// Module: Shared – domain model.

import Foundation

/// An alternative place from the bundled dataset, e.g. "Australian Museum".
/// Codable so the M2 owner can decode it straight from places.json.
nonisolated struct Place: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    var name: String
    var suburb: String
    var setting: ActivitySetting
    /// Entry cost in AUD (0 = free).
    var cost: Decimal
    var durationMinutes: Int
    var latitude: Double
    var longitude: Double
    /// Opening hour of the day, 0–23 (e.g. 10 = 10 am).
    var openingHour: Int
    /// Closing hour of the day, 1–24 (e.g. 17 = 5 pm).
    var closingHour: Int
    /// Image name in Assets.xcassets.
    var imageName: String
    /// Disruptions this place is a good alternative for.
    var suitableDisruptions: [Disruption]

    init(
        id: UUID = UUID(),
        name: String,
        suburb: String,
        setting: ActivitySetting,
        cost: Decimal,
        durationMinutes: Int,
        latitude: Double,
        longitude: Double,
        openingHour: Int,
        closingHour: Int,
        imageName: String,
        suitableDisruptions: [Disruption]
    ) {
        self.id = id
        self.name = name
        self.suburb = suburb
        self.setting = setting
        self.cost = cost
        self.durationMinutes = durationMinutes
        self.latitude = latitude
        self.longitude = longitude
        self.openingHour = openingHour
        self.closingHour = closingHour
        self.imageName = imageName
        self.suitableDisruptions = suitableDisruptions
    }
}
