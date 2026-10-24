//
//  MockPlaceRepository.swift
//  PlanShift
//
//  Created by Chang Chia ming on 2026/10/15.
//

import Foundation

actor MockPlaceRepository: PlaceRepository {
    private let places: [Place]

    init(places: [Place] = []) {
        self.places = places
    }

    func fetchAllPlaces() async throws -> [Place] {
        places
    }

    func importBundledPlacesIfNeeded() async throws {}
}
