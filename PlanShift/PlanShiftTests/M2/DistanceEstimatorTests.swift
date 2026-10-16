//
//  DistanceEstimatorTests.swift
//  PlanShiftTests
//
//  Created by Van Dao Le on 15/10/2026.
//

// Module: M2 tests – DistanceEstimator.

import XCTest
@testable import PlanShift

final class DistanceEstimatorTests: XCTestCase {
    func testOneHundredthOfADegreeOfLatitudeIsAboutOnePointOneKm() {
        let a = GeoCoordinate(latitude: -33.87, longitude: 151.2)
        let b = GeoCoordinate(latitude: -33.88, longitude: 151.2)
        XCTAssertEqual(DistanceEstimator.meters(from: a, to: b), 1_112, accuracy: 15)
    }

    func testWalkingMinutesIsAnEstimateWithAMinimumOfOne() {
        XCTAssertEqual(DistanceEstimator.walkingMinutes(forMeters: 1_000), 16) // 1000 × 1.25 ÷ 80
        XCTAssertEqual(DistanceEstimator.walkingMinutes(forMeters: 0), 1)
    }

    func testWalkingReasonTagIsLabelledAsEstimate() {
        XCTAssertEqual(ReasonTag.walkingMinutes(22).displayText, "~22 min walk")
    }
}
