//
//  MockBackupRepository.swift
//  PlanShift
//
//  Created by Chang Chia ming on 2026/10/15.
//

import Foundation

actor MockBackupRepository: BackupRepository {
    private var backups: [BackupOption]

    init(backups: [BackupOption] = []) {
        self.backups = backups
    }

    func fetchBackups(
        tripId: UUID
    ) async throws -> [BackupOption] {
        backups
            .filter { $0.tripId == tripId }
            .sorted { $0.savedAt > $1.savedAt }
    }

    func save(_ backup: BackupOption) async throws {
        if let index = backups.firstIndex(
            where: { $0.id == backup.id }
        ) {
            backups[index] = backup
        } else {
            backups.append(backup)
        }
    }

    func delete(id: UUID) async throws {
        backups.removeAll { $0.id == id }
    }

    func exists(
        placeId: UUID,
        tripId: UUID
    ) async throws -> Bool {
        backups.contains {
            $0.place.id == placeId && $0.tripId == tripId
        }
    }
}
