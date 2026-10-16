//
//  MockTripRepository.swift
//  PlanShift
//
//  Created by Chang Chia ming on 2026/10/15.
//

import Foundation

actor MockTripRepository: TripRepository {
    private var currentTrip: Trip?

    init(currentTrip: Trip? = nil) {
        self.currentTrip = currentTrip
    }

    func fetchCurrentTrip() async throws -> Trip? {
        currentTrip
    }

    func createTrip(_ trip: Trip) async throws {
        currentTrip = trip
    }

    func updateTrip(_ trip: Trip) async throws {
        guard currentTrip?.id == trip.id else {
            throw DomainError.persistenceFailure
        }

        currentTrip = trip
    }
}
