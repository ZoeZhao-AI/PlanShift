//
//  BundledPlaceRepository.swift
//  PlanShift
//
//  Created by Van Dao Le on 15/10/2026.
//

// Module: Shared – data layer (M2): PlaceRepository backed by the bundled places.json.

import Foundation
import os

/// Reads `places.json` once and serves it from memory, so importing is idempotent.
/// A Core Data repository can replace this behind `PlaceRepository` later.
actor BundledPlaceRepository: PlaceRepository {
    private let loadData: @Sendable () throws -> Data
    private var cache: PlacesDataset?

    init(bundle: Bundle = .main, resource: String = "places") {
        self.loadData = {
            guard let url = bundle.url(forResource: resource, withExtension: "json") else {
                throw PlacesDatasetError.fileMissing
            }
            return try Data(contentsOf: url)
        }
    }

    /// For tests: serve exactly this JSON.
    init(data: Data) {
        self.loadData = { data }
    }

    func fetchAllPlaces() async throws -> [Place] {
        try loadIfNeeded().places
    }

    func importBundledPlacesIfNeeded() async throws {
        _ = try loadIfNeeded()
    }

    private func loadIfNeeded() throws -> PlacesDataset {
        if let cache { return cache }
        let dataset = try PlacesDatasetLoader.load(from: loadData())
        if !dataset.skipped.isEmpty {
            let details = dataset.skipped.map { "\($0.identifier): \($0.reason)" }.joined(separator: "; ")
            Logger(subsystem: "com.utsstudent.zhaoziying.PlanShift", category: "places")
                .error("Skipped \(dataset.skipped.count, privacy: .public) invalid place record(s): \(details, privacy: .public)")
        }
        cache = dataset
        return dataset
    }
}
