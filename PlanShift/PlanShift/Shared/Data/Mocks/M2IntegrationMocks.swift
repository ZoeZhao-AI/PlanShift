//
//  M2IntegrationMocks.swift
//  PlanShift
//
//  Created by Van Dao Le on 15/10/2026.
//

// MOCK — NOT PRODUCTION CODE.
//
// M2 reads location through `LocationProviding`, whose real implementation is owned by M5
// (Widgets + Location). Until it lands, this stand-in lets the recommendation flow run end to
// end. It never touches CoreLocation. When M5's service exists, inject that in
// `RecommendationFlowViewModel.mocked(for:backups:)` and delete this file.

import Foundation

/// MOCK of `LocationProviding`. Scriptable; never touches CoreLocation.
@MainActor
final class MockLocationService: LocationProviding {
    var authorizationStatus: LocationAuthorizationStatus
    /// Status the user "chooses" when the permission dialog is requested.
    var statusAfterRequest: LocationAuthorizationStatus
    var coordinate: GeoCoordinate?
    private(set) var requestCount = 0
    private(set) var locationFetchCount = 0

    init(
        status: LocationAuthorizationStatus = .notDetermined,
        statusAfterRequest: LocationAuthorizationStatus = .authorizedWhenInUse,
        coordinate: GeoCoordinate? = nil
    ) {
        self.authorizationStatus = status
        self.statusAfterRequest = statusAfterRequest
        self.coordinate = coordinate
    }

    func requestWhenInUseAuthorization() async -> LocationAuthorizationStatus {
        guard authorizationStatus == .notDetermined else { return authorizationStatus }
        requestCount += 1
        authorizationStatus = statusAfterRequest
        return authorizationStatus
    }

    func currentLocation() async -> GeoCoordinate? {
        locationFetchCount += 1
        return authorizationStatus.isAuthorized ? coordinate : nil
    }
}
