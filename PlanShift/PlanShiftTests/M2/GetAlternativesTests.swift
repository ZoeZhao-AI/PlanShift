//
//  GetAlternativesTests.swift
//  PlanShiftTests
//
//  Created by Van Dao Le on 15/10/2026.
//

// Module: M2 tests – GetAlternatives loads places from the repository and ranks them.

import XCTest
@testable import PlanShift

final class GetAlternativesTests: XCTestCase {
    private struct StubPlaceRepository: PlaceRepository {
        let places: [Place]
        func fetchAllPlaces() async throws -> [Place] { places }
        func importBundledPlacesIfNeeded() async throws {}
    }

    private func getAlternatives(from places: [Place]) async throws -> [RankedAlternative] {
        let useCase = GetAlternativesUseCase(places: StubPlaceRepository(places: places), ranker: M2Fixtures.ranker)
        return try await useCase(
            activity: M2Fixtures.activity(), disruption: .attractionClosed,
            filters: M2Fixtures.open, origin: M2Fixtures.plannedOrigin
        )
    }

    func testRanksThePlacesFromTheRepository() async throws {
        let places = [M2Fixtures.place("Park"), M2Fixtures.place("Museum", setting: .indoor)]
        let result = try await getAlternatives(from: places)
        XCTAssertEqual(Set(result.map(\.place.id)), Set(places.map(\.id)))
    }

    func testThrowsWhenNothingMatches() async {
        do {
            _ = try await getAlternatives(from: [])
            XCTFail("expected noMatchingAlternatives")
        } catch {
            XCTAssertEqual(error as? DomainError, .noMatchingAlternatives)
        }
    }
}
