//
//  MockPlaceRepositoryTests.swift
//  PlanShiftTests
//
//  Created by Chang Chia ming on 2026/10/15.
//

import Foundation
import XCTest
@testable import PlanShift

final class MockPlaceRepositoryTests: XCTestCase {
    func testFetchReturnsEmptyWhenNoPlaces() async throws {
        let repository = MockPlaceRepository()

        let result = try await repository.fetchAllPlaces()

        XCTAssertTrue(result.isEmpty)
    }

    func testFetchReturnsInitialPlaces() async throws {
        let places = [
            makePlace(name: "Australian Museum"),
            makePlace(name: "Sydney Observatory")
        ]
        let repository = MockPlaceRepository(places: places)

        let result = try await repository.fetchAllPlaces()

        XCTAssertEqual(result, places)
    }

    func testRepeatedImportPreservesPlaces() async throws {
        let places = [makePlace(name: "Australian Museum")]
        let repository = MockPlaceRepository(places: places)

        try await repository.importBundledPlacesIfNeeded()
        try await repository.importBundledPlacesIfNeeded()
        let result = try await repository.fetchAllPlaces()

        XCTAssertEqual(result, places)
    }

    private func makePlace(name: String) -> Place {
        Place(
            name: name,
            suburb: "Sydney",
            setting: .indoor,
            cost: 0,
            durationMinutes: 60,
            latitude: -33.8688,
            longitude: 151.2093,
            openingHour: 9,
            closingHour: 17,
            imageName: "",
            suitableDisruptions: []
        )
    }
}
