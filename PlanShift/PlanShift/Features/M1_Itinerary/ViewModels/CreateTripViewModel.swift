//
//  CreateTripViewModel.swift
//  PlanShift
//
//  Created by Tianqi Li's Macbook pro on 18/10/2026.
//


import Foundation
import Observation

// Module: M1 - Itinerary Management

@MainActor
@Observable
final class CreateTripViewModel {

    var name = ""
    var startDate = Date()
    var endDate = Date()

    var isSaving = false
    var errorMessage: String?
    var createdTrip: Trip?

    private let createTripUseCase: CreateTripUseCase

    init(createTripUseCase: CreateTripUseCase) {
        self.createTripUseCase = createTripUseCase
    }

    func createTrip() async -> Bool {

        isSaving = true
        errorMessage = nil

        defer {
            isSaving = false
        }

        do {
            createdTrip = try await createTripUseCase.execute(
                name: name,
                startDate: startDate,
                endDate: endDate
            )

            return true

        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
