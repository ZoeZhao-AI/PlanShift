//
//  OriginResolver.swift
//  PlanShift
//
//  Created by Van Dao Le on 15/10/2026.
//

// Module: M2 – where distances are measured from (decision D-02).

import Foundation

nonisolated enum OriginSource: Equatable, Sendable {
    /// The device's current position (permission granted and a fix obtained).
    case device
    /// The planned activity's own coordinates (permission off, "Not now", or no fix).
    case plannedActivity
    /// Neither is usable. Distance filtering and distance tags are switched off.
    case unavailable
}

nonisolated struct ResolvedOrigin: Equatable, Sendable {
    let coordinate: GeoCoordinate?
    let source: OriginSource
}

nonisolated enum OriginResolver {
    /// A device position further than this from the planned activity is not a useful origin:
    /// the traveller is planning from far away (or the position is a simulator default), so
    /// every Sydney place would be "too far". 100 km covers all of Greater Sydney.
    static let maxDeviceDistanceFromActivityMeters = 100_000.0

    /// Device position if trustworthy and near the plan, else the planned activity's coordinates,
    /// else nothing. Never substitutes a made-up point: a missing origin means "no distances", not "0 m".
    static func resolve(device: GeoCoordinate?, activity: ItineraryActivity) -> ResolvedOrigin {
        let planned = GeoCoordinate(activity)
        if let device, device.isValid {
            let nearPlan = !planned.isValid
                || DistanceEstimator.meters(from: device, to: planned) <= maxDeviceDistanceFromActivityMeters
            if nearPlan { return ResolvedOrigin(coordinate: device, source: .device) }
        }
        if planned.isValid {
            return ResolvedOrigin(coordinate: planned, source: .plannedActivity)
        }
        return ResolvedOrigin(coordinate: nil, source: .unavailable)
    }
}
