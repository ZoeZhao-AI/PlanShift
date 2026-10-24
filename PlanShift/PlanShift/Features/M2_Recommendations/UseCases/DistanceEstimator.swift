//
//  DistanceEstimator.swift
//  PlanShift
//
//  Created by Van Dao Le on 15/10/2026.
//

// Module: M2 – distance and walking-time estimates.

import CoreLocation
import Foundation

/// Straight-line distance and a **heuristic** walking time.
///
/// There is no routing service in the app, so the walking time is `distance × 1.25 (detour
/// allowance) ÷ 80 m/min`. It is always presented as an estimate ("~22 min walk").
nonisolated enum DistanceEstimator {
    static let detourFactor = 1.25
    static let walkingMetersPerMinute = 80.0

    /// Geodesic distance in metres (CoreLocation).
    static func meters(from origin: GeoCoordinate, to destination: GeoCoordinate) -> Double {
        let a = CLLocation(latitude: origin.latitude, longitude: origin.longitude)
        let b = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
        return a.distance(from: b)
    }

    /// Estimated walking minutes, at least 1.
    static func walkingMinutes(forMeters meters: Double) -> Int {
        max(1, Int((meters * detourFactor / walkingMetersPerMinute).rounded()))
    }
}
