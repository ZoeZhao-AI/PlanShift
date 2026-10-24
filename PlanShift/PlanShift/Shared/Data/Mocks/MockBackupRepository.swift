//
//  MockBackupRepository.swift
//  PlanShift
//
//  Created by Chang Chia ming on 2026/10/15.
//

import Foundation

actor MockBackupRepository: BackupRepository {
    private var backups: [BackupOption]
    private let saveError: DomainError?
    private let deleteError: DomainError?

    init(
        backups: [BackupOption] = [],
        saveError: DomainError? = nil,
        deleteError: DomainError? = nil
    ) {
        self.backups = backups
        self.saveError = saveError
        self.deleteError = deleteError
    }

    func fetchBackups(
        tripId: UUID
    ) async throws -> [BackupOption] {
        backups
            .filter { $0.tripId == tripId }
            .sorted { $0.savedAt > $1.savedAt }
    }

    func save(_ backup: BackupOption) async throws {
        if let saveError {
            throw saveError
        }
        if let index = backups.firstIndex(
            where: { $0.id == backup.id }
        ) {
            backups[index] = backup
        } else {
            backups.append(backup)
        }
    }

    func delete(id: UUID) async throws {
        if let deleteError {
            throw deleteError
        }
        backups.removeAll { $0.id == id }
    }

    func exists(
        placeId: UUID,
        tripId: UUID
    ) async throws -> Bool {
        backups.contains { backup in
            guard backup.tripId == tripId,
                  case .place(let place) = backup.content else {
                return false
            }

            return place.id == placeId
        }
    }
}
