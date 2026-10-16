//
//  BackupOptionTests.swift
//  PlanShiftTests
//
//  Created by Chang Chia ming on 2026/10/16.
//

import Foundation
import XCTest
@testable import PlanShift

final class BackupOptionTests: XCTestCase {
    @MainActor
    func testPlaceBackupSurvivesEncodingAndDecoding() throws {
        let backup = BackupOption(
            tripId: PreviewSamples.trip.id,
            content: .place(PreviewSamples.australianMuseum),
            dayDate: Date(timeIntervalSince1970: 1_800_000_000),
            savedAt: Date(timeIntervalSince1970: 1_800_000_060)
        )

        let data = try JSONEncoder().encode(backup)
        let decoded = try JSONDecoder().decode(
            BackupOption.self,
            from: data
        )

        XCTAssertEqual(decoded, backup)
    }

    @MainActor
    func testActivityBackupSurvivesEncodingAndDecoding() throws {
        let activity = PreviewSamples.coastalWalk
        let backup = BackupOption(
            tripId: activity.tripId,
            content: .activity(activity),
            dayDate: activity.date,
            savedAt: Date(timeIntervalSince1970: 1_800_000_060)
        )

        let data = try JSONEncoder().encode(backup)
        let decoded = try JSONDecoder().decode(
            BackupOption.self,
            from: data
        )

        XCTAssertEqual(decoded, backup)
    }
}
