//
//  M2IntegrationMocks.swift
//  PlanShift
//
//  Created by Van Dao Le on 15/10/2026.
//

// MOCK — FOR INTEGRATION ONLY. NOT PRODUCTION CODE.
//
// M2 calls location and backup storage through protocols that other modules implement:
//   • LocationProviding  → real implementation owned by M5 (Widgets + Location)
//   • BackupSaving       → the SaveBackup use case, owned by M4
//   • BackupRepository   → real Core Data implementation owned by M3/M4
// Until those land, the types below let M2's view model run end to end (previews, manual
// integration runs, tests). They never touch CoreLocation or Core Data, and nothing here
// survives an app restart. When the real implementations exist, inject those instead and
// delete this file.

import Foundation

/// MOCK of `LocationProviding`. Scriptable; never touches CoreLocation.
@MainActor
final class MockLocationService: LocationProviding {
    var authorizationStatus: LocationAuthorizationStatus
    /// Status the user "chooses" when the permission dialog is requested.
    var statusAfterRequest: LocationAuthorizationStatus
    var coordinate: GeoCoordinate?
    private(set) var requestCount = 0
    private(set) var locationFetchCount = 0

    init(
        status: LocationAuthorizationStatus = .notDetermined,
        statusAfterRequest: LocationAuthorizationStatus = .authorizedWhenInUse,
        coordinate: GeoCoordinate? = nil
    ) {
        self.authorizationStatus = status
        self.statusAfterRequest = statusAfterRequest
        self.coordinate = coordinate
    }

    func requestWhenInUseAuthorization() async -> LocationAuthorizationStatus {
        guard authorizationStatus == .notDetermined else { return authorizationStatus }
        requestCount += 1
        authorizationStatus = statusAfterRequest
        return authorizationStatus
    }

    func currentLocation() async -> GeoCoordinate? {
        locationFetchCount += 1
        return authorizationStatus.isAuthorized ? coordinate : nil
    }
}

/// MOCK of `BackupRepository`. In memory only: the Backups tab (M4) does not see these backups.
actor InMemoryBackupRepository: BackupRepository {
    private var backups: [UUID: BackupOption] = [:]
    private(set) var failNextSave = false

    init(_ initial: [BackupOption] = []) {
        for backup in initial { backups[backup.id] = backup }
    }

    func setFailNextSave(_ value: Bool) { failNextSave = value }

    func fetchBackups(tripId: UUID) async throws -> [BackupOption] {
        backups.values.filter { $0.tripId == tripId }.sorted { $0.savedAt > $1.savedAt }
    }

    func save(_ backup: BackupOption) async throws {
        if failNextSave {
            failNextSave = false
            throw DomainError.persistenceFailure
        }
        backups[backup.id] = backup
    }

    func delete(id: UUID) async throws {
        backups[id] = nil
    }

    func exists(placeId: UUID, tripId: UUID) async throws -> Bool {
        backups.values.contains { backup in
            guard backup.tripId == tripId, case .place(let place) = backup.content else { return false }
            return place.id == placeId
        }
    }
}

/// MOCK of M4's SaveBackup use case, over any `BackupRepository`. Rejects a second save of the same place.
nonisolated struct RepositoryBackupSaver: BackupSaving {
    let repository: BackupRepository
    var now: @Sendable () -> Date = { .now }

    func isSaved(placeId: UUID, tripId: UUID) async throws -> Bool {
        try await repository.exists(placeId: placeId, tripId: tripId)
    }

    func save(place: Place, for activity: ItineraryActivity) async throws {
        if try await repository.exists(placeId: place.id, tripId: activity.tripId) {
            throw DomainError.duplicateBackup
        }
        let backup = BackupOption(tripId: activity.tripId, content: .place(place), dayDate: activity.date, savedAt: now())
        try await repository.save(backup)
    }
}
