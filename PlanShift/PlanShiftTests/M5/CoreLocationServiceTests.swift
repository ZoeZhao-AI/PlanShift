// Module: M5 tests – CoreLocationService against a fake location manager. No system dialog, no real GPS.

import CoreLocation
import XCTest
@testable import PlanShift

@MainActor
final class CoreLocationServiceTests: XCTestCase {
    private let sydney = CLLocation(latitude: -33.8688, longitude: 151.2093)
    private let fixedNow = Date(timeIntervalSince1970: 1_800_000_000)

    private func makeService(
        _ fake: FakeLocationManager,
        timeout: Duration = .seconds(5)
    ) -> CoreLocationService {
        let now = fixedNow
        return CoreLocationService(manager: fake, timeout: timeout, maxFixAge: 120, now: { now })
    }

    private func location(latitude: Double, longitude: Double, accuracy: Double = 50, age: TimeInterval = 0) -> CLLocation {
        CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            altitude: 0, horizontalAccuracy: accuracy, verticalAccuracy: 0,
            timestamp: fixedNow.addingTimeInterval(-age)
        )
    }

    /// Lets tasks started with `Task { }` run up to their first suspension.
    private func settle() async {
        for _ in 0..<10 { await Task.yield() }
    }

    // MARK: - Status

    func testStatusMapsEverySystemValue() {
        let cases: [(CLAuthorizationStatus, LocationAuthorizationStatus)] = [
            (.notDetermined, .notDetermined),
            (.restricted, .restricted),
            (.denied, .denied),
            (.authorizedWhenInUse, .authorizedWhenInUse),
            (.authorizedAlways, .authorizedWhenInUse),
        ]
        for (system, expected) in cases {
            let service = makeService(FakeLocationManager(status: system))
            XCTAssertEqual(service.authorizationStatus, expected, "\(system.rawValue)")
        }
    }

    // MARK: - Permission

    func testRequestAsksTheSystemOnceAndReturnsTheAnswer() async {
        let fake = FakeLocationManager(status: .notDetermined)
        let service = makeService(fake)

        let task = Task { await service.requestWhenInUseAuthorization() }
        await settle()
        XCTAssertEqual(fake.permissionRequests, 1)

        fake.userAnswers(.authorizedWhenInUse)
        let result = await task.value
        XCTAssertEqual(result, .authorizedWhenInUse)
    }

    func testDenyingReturnsDenied() async {
        let fake = FakeLocationManager(status: .notDetermined)
        let service = makeService(fake)

        let task = Task { await service.requestWhenInUseAuthorization() }
        await settle()
        fake.userAnswers(.denied)

        let result = await task.value
        XCTAssertEqual(result, .denied)
        XCTAssertTrue(result.isBlocked)
    }

    func testInitialNotDeterminedCallbackDoesNotResolveTheRequest() async {
        let fake = FakeLocationManager(status: .notDetermined)
        let service = makeService(fake)

        let task = Task { await service.requestWhenInUseAuthorization() }
        await settle()
        // CoreLocation reports the current (undecided) status right after the delegate is set.
        fake.onAuthorizationChange?()
        await settle()
        fake.userAnswers(.authorizedWhenInUse)

        let result = await task.value
        XCTAssertEqual(result, .authorizedWhenInUse)
    }

    func testAlreadyDecidedNeverShowsTheDialogAgain() async {
        for status in [CLAuthorizationStatus.denied, .restricted, .authorizedWhenInUse] {
            let fake = FakeLocationManager(status: status)
            let service = makeService(fake)
            _ = await service.requestWhenInUseAuthorization()
            XCTAssertEqual(fake.permissionRequests, 0, "\(status.rawValue)")
        }
    }

    func testConcurrentRequestsShareOneDialog() async {
        let fake = FakeLocationManager(status: .notDetermined)
        let service = makeService(fake)

        let first = Task { await service.requestWhenInUseAuthorization() }
        let second = Task { await service.requestWhenInUseAuthorization() }
        await settle()
        XCTAssertEqual(fake.permissionRequests, 1)

        fake.userAnswers(.authorizedWhenInUse)
        let results = await [first.value, second.value]
        XCTAssertEqual(results, [.authorizedWhenInUse, .authorizedWhenInUse])
    }

    // MARK: - Position

    func testNoPositionAndNoRequestWithoutPermission() async {
        for status in [CLAuthorizationStatus.notDetermined, .denied, .restricted] {
            let fake = FakeLocationManager(status: status)
            let service = makeService(fake)

            let result = await service.currentLocation()

            XCTAssertNil(result, "\(status.rawValue)")
            XCTAssertEqual(fake.locationRequests, 0, "\(status.rawValue)")
        }
    }

    func testReturnsTheFixTheSystemDelivers() async {
        let fake = FakeLocationManager(status: .authorizedWhenInUse)
        let service = makeService(fake)

        let task = Task { await service.currentLocation() }
        await settle()
        XCTAssertEqual(fake.locationRequests, 1)
        fake.onLocations?([sydney])

        let result = await task.value
        XCTAssertEqual(result, GeoCoordinate(latitude: -33.8688, longitude: 151.2093))
    }

    func testNewestValidFixWins() async {
        let fake = FakeLocationManager(status: .authorizedWhenInUse)
        let service = makeService(fake)

        let task = Task { await service.currentLocation() }
        await settle()
        fake.onLocations?([
            location(latitude: -33.0, longitude: 151.0, age: 30),
            location(latitude: -34.0, longitude: 150.0, age: 1),
            location(latitude: -35.0, longitude: 149.0, accuracy: -1, age: 0), // invalid, newest
        ])

        let result = await task.value
        XCTAssertEqual(result, GeoCoordinate(latitude: -34.0, longitude: 150.0))
    }

    func testFailureGivesNilNotAnError() async {
        let fake = FakeLocationManager(status: .authorizedWhenInUse)
        let service = makeService(fake)

        let task = Task { await service.currentLocation() }
        await settle()
        fake.onFailure?(CLError(.locationUnknown))

        let result = await task.value
        XCTAssertNil(result)
    }

    func testInvalidFixGivesNil() async {
        let fake = FakeLocationManager(status: .authorizedWhenInUse)
        let service = makeService(fake)

        let task = Task { await service.currentLocation() }
        await settle()
        fake.onLocations?([location(latitude: -33.8, longitude: 151.2, accuracy: -1)])

        let result = await task.value
        XCTAssertNil(result)
    }

    func testTimesOutWithNilWhenNoSignal() async {
        let fake = FakeLocationManager(status: .authorizedWhenInUse)
        let service = makeService(fake, timeout: .milliseconds(50))

        let result = await service.currentLocation() // the fake never answers

        XCTAssertNil(result)
        XCTAssertEqual(fake.locationRequests, 1)
    }

    func testFreshCachedFixIsReturnedWithoutANewRequest() async {
        let fake = FakeLocationManager(status: .authorizedWhenInUse)
        fake.lastKnownLocation = location(latitude: -33.9, longitude: 151.1, age: 30)
        let service = makeService(fake)

        let result = await service.currentLocation()

        XCTAssertEqual(result, GeoCoordinate(latitude: -33.9, longitude: 151.1))
        XCTAssertEqual(fake.locationRequests, 0)
    }

    func testStaleCachedFixTriggersANewRequest() async {
        let fake = FakeLocationManager(status: .authorizedWhenInUse)
        fake.lastKnownLocation = location(latitude: -33.9, longitude: 151.1, age: 600)
        let service = makeService(fake)

        let task = Task { await service.currentLocation() }
        await settle()
        XCTAssertEqual(fake.locationRequests, 1)
        fake.onLocations?([sydney])

        let result = await task.value
        XCTAssertEqual(result, GeoCoordinate(latitude: -33.8688, longitude: 151.2093))
    }

    func testConcurrentCallsShareOneRequest() async {
        let fake = FakeLocationManager(status: .authorizedWhenInUse)
        let service = makeService(fake)

        let first = Task { await service.currentLocation() }
        let second = Task { await service.currentLocation() }
        await settle()
        XCTAssertEqual(fake.locationRequests, 1)
        fake.onLocations?([sydney])

        let results = await [first.value, second.value]
        XCTAssertEqual(results.compactMap { $0 }.count, 2)
    }
}

/// A scriptable stand-in for `CLLocationManager`.
@MainActor
private final class FakeLocationManager: LocationManaging {
    var authorizationStatus: CLAuthorizationStatus
    var lastKnownLocation: CLLocation?
    var onAuthorizationChange: (() -> Void)?
    var onLocations: (([CLLocation]) -> Void)?
    var onFailure: ((Error) -> Void)?

    private(set) var permissionRequests = 0
    private(set) var locationRequests = 0

    init(status: CLAuthorizationStatus) {
        self.authorizationStatus = status
    }

    func requestWhenInUseAuthorization() { permissionRequests += 1 }
    func requestLocation() { locationRequests += 1 }

    /// The user taps an answer in the system dialog.
    func userAnswers(_ status: CLAuthorizationStatus) {
        authorizationStatus = status
        onAuthorizationChange?()
    }
}
