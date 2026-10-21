//
//  CreateTripUseCase.swift
//  PlanShift
//
//  Created by Tianqi Li's Macbook pro on 15/10/2026.
//

import Foundation
// Module: M1 - Itinerary Management

struct CreateTripUseCase {

    let repository: any TripRepository

    func execute(
        name: String,
        startDate: Date,
        endDate: Date
    ) async throws -> Trip {

        let trimmedName = name.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmedName.isEmpty else {
            throw DomainError.emptyName
        }

        let calendar = Calendar.current

        guard calendar.startOfDay(for: endDate) >=
              calendar.startOfDay(for: startDate) else {
            throw DomainError.invalidTripDates
        }

        let trip = Trip(
            name: trimmedName,
            startDate: startDate,
            endDate: endDate
        )

        try await repository.createTrip(trip)

        return trip
    }
}
