//
//  GeoCoordinate.swift
//  PlanShift
//
//  Created by Van Dao Le on 15/10/2026.
//

// Module: Shared – domain model.

import Foundation

/// A latitude/longitude pair. Plain value so use cases and tests need no CoreLocation objects.
nonisolated struct GeoCoordinate: Hashable, Codable, Sendable {
    let latitude: Double
    let longitude: Double

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    /// False for out-of-range values and for (0, 0), which means "not set" in stored activities.
    var isValid: Bool {
        (-90...90).contains(latitude) && (-180...180).contains(longitude)
            && !(latitude == 0 && longitude == 0)
    }
}

extension GeoCoordinate {
    nonisolated init(_ place: Place) {
        self.init(latitude: place.latitude, longitude: place.longitude)
    }

    nonisolated init(_ activity: ItineraryActivity) {
        self.init(latitude: activity.latitude, longitude: activity.longitude)
    }
}
