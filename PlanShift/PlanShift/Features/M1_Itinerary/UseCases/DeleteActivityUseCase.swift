//
//  DeleteActivityUseCase.swift
//  PlanShift
//
//  Created by Tianqi Li's Macbook pro on 15/10/2026.
//

import Foundation
// Module: M1 - Itinerary Management

struct DeleteActivityUseCase {

    let repository: any ActivityRepository

    func execute(id: UUID) async throws {
        try await repository.delete(id: id)
    }
}
