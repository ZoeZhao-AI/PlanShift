//
//  M1InMemoryTripRepository.swift
//  PlanShift
//
//  Created by Tianqi Li's Macbook pro on 19/10/2026.
//

import Foundation

// Temporary in-memory storage for developing M1 screens.
// The production app must use the Core Data repository.
actor M1InMemoryTripRepository: TripRepository {

    static let shared = M1InMemoryTripRepository()

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
