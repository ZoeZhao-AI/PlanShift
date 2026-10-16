//
//  PlacesDatasetLoader.swift
//  PlanShift
//
//  Created by Van Dao Le on 15/10/2026.
//

// Module: Shared – data layer (M2): decodes and validates the bundled places.json.

import Foundation

nonisolated struct PlacesDataset: Sendable {
    let places: [Place]
    /// Records that were dropped, with the reason. The file still loads if at least one place is valid.
    let skipped: [SkippedPlaceRecord]
}

nonisolated struct SkippedPlaceRecord: Equatable, Sendable {
    let identifier: String
    let reason: String
}

nonisolated enum PlacesDatasetError: LocalizedError, Equatable, Sendable {
    case fileMissing
    case unreadable
    case unsupportedVersion(Int)
    case noValidPlaces

    var errorDescription: String? {
        switch self {
        case .fileMissing: "The built-in list of places could not be found."
        case .unreadable: "The built-in list of places could not be read."
        case .unsupportedVersion: "The built-in list of places is in an unsupported format."
        case .noValidPlaces: "The built-in list of places is empty."
        }
    }
}

/// Decodes `places.json` (schema version 1) into domain `Place` values.
///
/// Validation is strict on purpose: an invalid record is **skipped**, never guessed at, so the
/// ranker never sees invented data. Dataset conventions are in `docs/PLACES_DATA_SOURCES.md`:
/// - `access == "openAccess"`: public open space, no gated hours, stored as 0...24.
/// - `access == "scheduled"`: real opening hours, rounded inward to whole hours.
nonisolated enum PlacesDatasetLoader {
    static let supportedVersion = 1
    /// Rough bounding box around Greater Sydney; rejects swapped or mistyped coordinates.
    static let latitudeRange = -34.3...(-33.4)
    static let longitudeRange = 150.7...151.6

    static func load(from data: Data) throws -> PlacesDataset {
        guard let file = try? JSONDecoder().decode(File.self, from: data) else {
            throw PlacesDatasetError.unreadable
        }
        guard file.version == supportedVersion else {
            throw PlacesDatasetError.unsupportedVersion(file.version)
        }

        var places: [Place] = []
        var skipped: [SkippedPlaceRecord] = []
        var seenIds = Set<UUID>()

        for (index, entry) in file.places.enumerated() {
            guard let record = entry.record else {
                skipped.append(SkippedPlaceRecord(identifier: "#\(index)", reason: "undecodable record"))
                continue
            }
            do {
                let place = try record.validated()
                guard seenIds.insert(place.id).inserted else { throw RecordError("duplicate id") }
                places.append(place)
            } catch {
                let reason = (error as? RecordError)?.reason ?? "invalid"
                skipped.append(SkippedPlaceRecord(identifier: record.name, reason: reason))
            }
        }
        guard !places.isEmpty else { throw PlacesDatasetError.noValidPlaces }
        return PlacesDataset(places: places, skipped: skipped)
    }

    // MARK: - File format

    private struct File: Decodable {
        let version: Int
        let places: [Entry]
    }

    /// One array element; `record` is `nil` if it cannot be decoded, so one bad record does not fail the file.
    private struct Entry: Decodable {
        let record: PlaceRecord?

        init(from decoder: Decoder) {
            record = try? PlaceRecord(from: decoder)
        }
    }

    private struct RecordError: Error {
        let reason: String
        init(_ reason: String) { self.reason = reason }
    }

    private struct PlaceRecord: Decodable {
        let id: UUID
        let name: String
        let suburb: String
        let setting: ActivitySetting
        let costAUD: Decimal
        let durationMinutes: Int
        let access: String
        let openingHour: Int
        let closingHour: Int
        let latitude: Double
        let longitude: Double
        let imageName: String
        let suitableDisruptions: [Disruption]
        let sourceURL: String

        func validated() throws -> Place {
            let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            let suburb = suburb.trimmingCharacters(in: .whitespacesAndNewlines)
            let isOpenAllDay = openingHour == 0 && closingHour == 24

            try require(!name.isEmpty, "empty name")
            try require(!suburb.isEmpty, "empty suburb")
            try require(costAUD >= 0, "negative cost")
            try require((5...720).contains(durationMinutes), "duration out of range")
            try require(
                PlacesDatasetLoader.latitudeRange.contains(latitude) && PlacesDatasetLoader.longitudeRange.contains(longitude),
                "coordinates outside Sydney"
            )
            try require(
                (0...23).contains(openingHour) && (1...24).contains(closingHour) && openingHour < closingHour,
                "invalid opening window"
            )
            switch access {
            case "openAccess": try require(isOpenAllDay, "openAccess must be 0-24")
            case "scheduled": try require(!isOpenAllDay, "scheduled place cannot be 0-24")
            default: throw RecordError("unknown access value")
            }
            try require(!imageName.isEmpty, "missing imageName")
            try require(!suitableDisruptions.isEmpty, "no suitable disruptions")
            try require(URL(string: sourceURL).map { ["http", "https"].contains($0.scheme) } ?? false, "missing source URL")

            return Place(
                id: id, name: name, suburb: suburb, setting: setting, cost: costAUD,
                durationMinutes: durationMinutes, latitude: latitude, longitude: longitude,
                openingHour: openingHour, closingHour: closingHour, imageName: imageName,
                suitableDisruptions: suitableDisruptions
            )
        }

        private func require(_ condition: Bool, _ reason: String) throws {
            if !condition { throw RecordError(reason) }
        }
    }
}
