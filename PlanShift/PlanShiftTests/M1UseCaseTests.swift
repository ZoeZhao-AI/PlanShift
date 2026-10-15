//
//  M1UseCaseTests.swift
//  PlanShiftTests
//
//  Created by Tianqi Li's Macbook pro on 15/10/2026.
//

import Foundation
import XCTest
@testable import PlanShift

actor MockTripRepository: TripRepository {

    private var currentTrip: Trip?

    func fetchCurrentTrip() async throws -> Trip? {
        return currentTrip
    }

    func createTrip(_ trip: Trip) async throws {
        currentTrip = trip
    }

    func updateTrip(_ trip: Trip) async throws {
        currentTrip = trip
    }
}

final class M1UseCaseTests: XCTestCase {

    func testCreateTrip() async throws {

        let repository = MockTripRepository()

        let useCase = CreateTripUseCase(
            repository: repository
        )

        let startDate = Date()
        let endDate = Calendar.current.date(
            byAdding: .day,
            value: 2,
            to: startDate
        )!

        let trip = try await useCase.execute(
            name: "Sydney Weekend",
            startDate: startDate,
            endDate: endDate
        )

        XCTAssertEqual(trip.name, "Sydney Weekend")

        let savedTrip = try await repository.fetchCurrentTrip()

        XCTAssertEqual(savedTrip?.id, trip.id)
    }
}
