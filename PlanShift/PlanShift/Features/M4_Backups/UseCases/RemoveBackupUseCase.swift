// Module: M4 – removes a saved backup.

import Foundation

/// Deletes one backup by its id.
nonisolated struct RemoveBackupUseCase: Sendable {
    private let repository: any BackupRepository

    init(repository: any BackupRepository) {
        self.repository = repository
    }

    func execute(id: UUID) async throws {
        try await repository.delete(id: id)
    }
}
