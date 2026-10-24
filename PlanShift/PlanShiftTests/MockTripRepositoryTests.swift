//
//  MockTripRepositoryTests.swift
//  PlanShiftTests
//
//  Created by Chang Chia ming on 2026/10/15.
//

import Foundation
import XCTest
@testable import PlanShift

final class MockTripRepositoryTests: XCTestCase {
    func testFetchReturnsNilWhenEmpty() async throws {
        let repository = MockTripRepository()

        let result = try await repository.fetchCurrentTrip()

        XCTAssertNil(result)
    }

    func testFetchReturnsInitialTrip() async throws {
        let trip = makeTrip()
        let repository = MockTripRepository(currentTrip: trip)

        let result = try await repository.fetchCurrentTrip()

        XCTAssertEqual(result, trip)
    }

    func testCreateStoresTrip() async throws {
        let repository = MockTripRepository()
        let trip = makeTrip()

        try await repository.createTrip(trip)
        let result = try await repository.fetchCurrentTrip()

        XCTAssertEqual(result, trip)
    }

    func testUpdateStoresChanges() async throws {
        let trip = makeTrip()
        let repository = MockTripRepository(currentTrip: trip)
        var updatedTrip = trip
        updatedTrip.name = "Updated Sydney Trip"
        updatedTrip.endDate = trip.endDate.addingTimeInterval(86_400)

        try await repository.updateTrip(updatedTrip)
        let result = try await repository.fetchCurrentTrip()

        XCTAssertEqual(result, updatedTrip)
    }

    func testUpdateWithoutCurrentTripThrows() async throws {
        let repository = MockTripRepository()

        do {
            try await repository.updateTrip(makeTrip())
            XCTFail("Expected persistenceFailure.")
        } catch {
            XCTAssertEqual(
                error as? DomainError,
                .persistenceFailure
            )
        }

        let result = try await repository.fetchCurrentTrip()
        XCTAssertNil(result)
    }

    func testUpdateWithDifferentIDPreservesCurrentTrip() async throws {
        let trip = makeTrip()
        let repository = MockTripRepository(currentTrip: trip)
        let anotherTrip = makeTrip()

        do {
            try await repository.updateTrip(anotherTrip)
            XCTFail("Expected persistenceFailure.")
        } catch {
            XCTAssertEqual(
                error as? DomainError,
                .persistenceFailure
            )
        }

        let result = try await repository.fetchCurrentTrip()
        XCTAssertEqual(result, trip)
    }

    private func makeTrip() -> Trip {
        let startDate = Date(timeIntervalSince1970: 1_800_000_000)

        return Trip(
            name: "Sydney Trip",
            startDate: startDate,
            endDate: startDate.addingTimeInterval(86_400)
        )
    }
}
