//
//  OriginResolverTests.swift
//  PlanShiftTests
//
//  Created by Van Dao Le on 15/10/2026.
//

// Module: M2 tests – OriginResolver (decision D-02).

import XCTest
@testable import PlanShift

final class OriginResolverTests: XCTestCase {
    func testDevicePositionWinsWhenValid() {
        let device = GeoCoordinate(latitude: -33.8688, longitude: 151.2093)
        let origin = OriginResolver.resolve(device: device, activity: M2Fixtures.activity())
        XCTAssertEqual(origin.source, .device)
        XCTAssertEqual(origin.coordinate, device)
    }

    func testFallsBackToPlannedActivityWithoutDevicePosition() {
        let origin = OriginResolver.resolve(device: nil, activity: M2Fixtures.activity())
        XCTAssertEqual(origin.source, .plannedActivity)
        XCTAssertEqual(origin.coordinate, M2Fixtures.origin)
    }

    func testInvalidDevicePositionIsIgnored() {
        let origin = OriginResolver.resolve(device: GeoCoordinate(latitude: 0, longitude: 0), activity: M2Fixtures.activity())
        XCTAssertEqual(origin.source, .plannedActivity)
    }

    func testDevicePositionFarFromThePlanIsIgnored() {
        // e.g. the traveller is planning from another country, or a simulator's default Cupertino position.
        let cupertino = GeoCoordinate(latitude: 37.3349, longitude: -122.0090)
        let origin = OriginResolver.resolve(device: cupertino, activity: M2Fixtures.activity())
        XCTAssertEqual(origin.source, .plannedActivity)
        XCTAssertEqual(origin.coordinate, M2Fixtures.origin)
    }

    func testUnavailableWhenNeitherIsUsable() {
        let unset = M2Fixtures.activity(latitude: 0, longitude: 0)
        let origin = OriginResolver.resolve(device: nil, activity: unset)
        XCTAssertEqual(origin.source, .unavailable)
        XCTAssertNil(origin.coordinate, "a missing origin must never become a made-up point")
    }
}
