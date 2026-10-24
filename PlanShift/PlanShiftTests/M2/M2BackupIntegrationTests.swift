// Module: M2 tests – M2 bookmark → M4 SaveBackupUseCase → Core Data (in-memory store). No mocks of the backup layer.

import XCTest
@testable import PlanShift

@MainActor
final class M2BackupIntegrationTests: XCTestCase {
    private var persistence: PersistenceController!
    private var repository: CoreDataBackupRepository!
    private let activity = M2Fixtures.activity()

    override func setUp() async throws {
        persistence = try PersistenceController(inMemory: true)
        repository = CoreDataBackupRepository(container: persistence.container)
    }

    override func tearDown() async throws {
        repository = nil
        persistence = nil
    }

    private func makeModel(backups: BackupSaving) -> RecommendationFlowViewModel {
        RecommendationFlowViewModel(
            activity: activity,
            getAlternatives: GetAlternativesUseCase(places: BundledPlaceRepository()),
            backups: backups,
            location: NoLocation()
        )
    }

    private func alternative(_ place: Place) -> RankedAlternative {
        RankedAlternative(rank: 1, place: place, distanceMeters: nil, walkingMinutes: nil, reasons: [], score: 0.5)
    }

    func testBookmarkCallsSaveWithPlaceAndActivity() async {
        let spy = SpyBackupSaver()
        let model = makeModel(backups: spy)
        let place = M2Fixtures.place("Museum")

        await model.bookmark(alternative(place))

        XCTAssertEqual(spy.saved.count, 1)
        XCTAssertEqual(spy.saved.first?.place.id, place.id)
        XCTAssertEqual(spy.saved.first?.activity.id, activity.id)
    }

    func testBookmarkPersistsBackupInCoreData() async throws {
        let model = makeModel(backups: SaveBackupUseCase(repository: repository))
        let place = M2Fixtures.place("Museum")

        await model.bookmark(alternative(place))

        XCTAssertEqual(model.toast?.kind, .success)
        XCTAssertTrue(model.savedPlaceIds.contains(place.id))
        let stored = try await repository.fetchBackups(tripId: activity.tripId)
        XCTAssertEqual(stored.count, 1)
        guard case .place(let storedPlace) = stored.first?.content else {
            return XCTFail("Expected a place backup")
        }
        XCTAssertEqual(storedPlace.id, place.id)
        XCTAssertEqual(stored.first?.tripId, activity.tripId)
    }

    func testBookmarkSurvivesANewRepositoryOnTheSameStore() async throws {
        let model = makeModel(backups: SaveBackupUseCase(repository: repository))
        let place = M2Fixtures.place("Museum")
        await model.bookmark(alternative(place))

        // What the Backups tab does: read through its own repository on the same container.
        let other = CoreDataBackupRepository(container: persistence.container)
        let stored = try await other.fetchBackups(tripId: activity.tripId)

        XCTAssertEqual(stored.count, 1)
    }

    func testSecondBookmarkOfSamePlaceShowsDuplicateWarningAndKeepsOneBackup() async throws {
        let model = makeModel(backups: SaveBackupUseCase(repository: repository))
        let place = M2Fixtures.place("Museum")

        await model.bookmark(alternative(place))
        await model.bookmark(alternative(place))

        XCTAssertEqual(model.toast?.kind, .warning)
        let stored = try await repository.fetchBackups(tripId: activity.tripId)
        XCTAssertEqual(stored.count, 1)
    }

    func testReplaceSavesOriginalToSharedCoreDataRepository() async throws {
        let original = PreviewSamples.coastalWalk
        let useCase = ReplaceActivityUseCase(
            activityRepository: MockActivityRepository(activities: [original]),
            backupRepository: repository
        )

        _ = try await useCase.execute(activity: original, with: PreviewSamples.australianMuseum)

        let stored = try await repository.fetchBackups(tripId: original.tripId)
        XCTAssertEqual(stored.count, 1)
        guard case .activity(let saved) = stored.first?.content else {
            return XCTFail("Expected an original-plan backup")
        }
        XCTAssertEqual(saved.id, original.id)
    }
}

/// Records every call to `save`, to prove the bookmark reaches the M4 use case.
private final class SpyBackupSaver: BackupSaving, @unchecked Sendable {
    private let lock = NSLock()
    private var calls: [(place: Place, activity: ItineraryActivity)] = []

    var saved: [(place: Place, activity: ItineraryActivity)] {
        lock.withLock { calls }
    }

    func isSaved(placeId: UUID, tripId: UUID) async throws -> Bool { false }

    func save(place: Place, for activity: ItineraryActivity) async throws {
        lock.withLock { calls.append((place, activity)) }
    }
}

/// Location is irrelevant to the backup tests: permission is undecided and there is never a fix.
@MainActor
private final class NoLocation: LocationProviding {
    var authorizationStatus: LocationAuthorizationStatus { .notDetermined }
    func requestWhenInUseAuthorization() async -> LocationAuthorizationStatus { .notDetermined }
    func currentLocation() async -> GeoCoordinate? { nil }
}
