//
//  LocationProviding.swift
//  PlanShift
//
//  Created by Van Dao Le on 15/10/2026.
//

// Module: Shared – service protocol (consumed by M2, owned by M5).
//
// PROVISIONAL: M2 needed this to ask for location. The M5 owner may rename or extend it;
// M2 only depends on this protocol, so swapping the implementation is a one-line change.

import Foundation

/// App permission plus device-wide Location Services availability.
nonisolated enum LocationAuthorizationStatus: Equatable, Sendable {
    case notDetermined
    case denied
    case restricted
    case servicesDisabled
    case authorizedWhenInUse

    var isAuthorized: Bool { self == .authorizedWhenInUse }
    var isBlocked: Bool { self == .denied || self == .restricted || self == .servicesDisabled }
}

/// Reads location permission and a one-shot position. Foreground "When In Use" only.
@MainActor
protocol LocationProviding: AnyObject {
    var authorizationStatus: LocationAuthorizationStatus { get }
    /// Shows the iOS permission dialog if the status is `.notDetermined`; otherwise returns the current status.
    func requestWhenInUseAuthorization() async -> LocationAuthorizationStatus
    /// One position fix, or `nil` if unauthorised, unavailable or timed out. Never throws.
    func currentLocation() async -> GeoCoordinate?
}
