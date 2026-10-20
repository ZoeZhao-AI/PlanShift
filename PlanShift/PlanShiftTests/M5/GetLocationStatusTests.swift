import CoreLocation
import Observation
import XCTest
@testable import PlanShift

final class GetLocationStatusTests: XCTestCase {
    @MainActor
    func testReadingUndeterminedStatusDoesNotRequestPermissionOrPosition() throws {
        let service = M5LocationStub(status: .notDetermined)
        XCTAssertEqual(try GetLocationStatus(location: service).execute(), .notDetermined)
        XCTAssertEqual(service.requestCount, 0)
        XCTAssertEqual(service.locationFetchCount, 0)
    }

    @MainActor
    func testAuthorizedStatusIsReturnedWithoutFetchingPosition() throws {
        let service = M5LocationStub(status: .authorizedWhenInUse)
        XCTAssertEqual(try GetLocationStatus(location: service).execute(), .authorizedWhenInUse)
        XCTAssertEqual(service.locationFetchCount, 0)
    }

    @MainActor
    func testDeniedAndRestrictedMapToDomainError() {
        for status in [LocationAuthorizationStatus.denied, .restricted] {
            let service = M5LocationStub(status: status)
            XCTAssertThrowsError(try GetLocationStatus(location: service).execute()) {
                XCTAssertEqual($0 as? DomainError, .locationDenied)
            }
            XCTAssertEqual(service.requestCount, 0)
        }
    }

    @MainActor
    func testViewModelOnlyRequestsAfterExplicitAction() async {
        let service = M5LocationStub(statusAfterRequest: .denied)
        let model = LocationPermissionViewModel(location: service)
        model.refresh()
        XCTAssertEqual(service.requestCount, 0)
        await model.allowLocation()
        XCTAssertEqual(service.requestCount, 1)
        XCTAssertEqual(model.status, .denied)
        XCTAssertEqual(model.error, .locationDenied)
        XCTAssertFalse(model.isRequesting)
        XCTAssertEqual(service.locationFetchCount, 0)
        await model.allowLocation()
        XCTAssertEqual(service.requestCount, 1)
    }

    @MainActor
    func testReturningFromSettingsClearsDeniedError() {
        let service = M5LocationStub(status: .denied)
        let model = LocationPermissionViewModel(location: service)
        model.refresh()
        XCTAssertEqual(model.error, .locationDenied)
        service.authorizationStatus = .authorizedWhenInUse
        model.refresh()
        XCTAssertEqual(model.status, .authorizedWhenInUse)
        XCTAssertNil(model.error)
    }
    @MainActor
    func testPermissionGrantedByActionClearsError() async {
        let service = M5LocationStub()
        let model = LocationPermissionViewModel(location: service)
        await model.allowLocation()
        XCTAssertEqual(model.status, .authorizedWhenInUse)
        XCTAssertNil(model.error)
        XCTAssertEqual(service.locationFetchCount, 0)
    }

    @MainActor
    func testRestrictedStateDoesNotRequestAgain() async {
        let service = M5LocationStub(status: .restricted)
        let model = LocationPermissionViewModel(location: service)
        await model.allowLocation()
        XCTAssertEqual(service.requestCount, 0)
        XCTAssertEqual(model.status, .restricted)
    }

    @MainActor
    func testOpeningSettingsHandlesFailureAndRetry() async {
        var openCount = 0
        let model = LocationPermissionViewModel(location: M5LocationStub(status: .denied)) {
            openCount += 1
            return openCount > 1
        }
        await model.openSettings()
        XCTAssertNotNil(model.settingsError)
        await model.openSettings()
        XCTAssertNil(model.settingsError)
        XCTAssertEqual(openCount, 2)
    }

    func testCoreLocationAuthorizationMapping() {
        XCTAssertEqual(CoreLocationService.mapAuthorization(.notDetermined), .notDetermined)
        XCTAssertEqual(CoreLocationService.mapAuthorization(.denied), .denied)
        XCTAssertEqual(CoreLocationService.mapAuthorization(.restricted), .restricted)
        XCTAssertEqual(CoreLocationService.mapAuthorization(.authorizedWhenInUse), .authorizedWhenInUse)
        XCTAssertEqual(CoreLocationService.mapAuthorization(.authorizedAlways), .authorizedWhenInUse)
    }
}

@MainActor
@Observable
final class M5LocationStub: LocationProviding {
    nonisolated deinit {}

    var authorizationStatus: LocationAuthorizationStatus
    var statusAfterRequest: LocationAuthorizationStatus
    private(set) var requestCount = 0
    private(set) var locationFetchCount = 0

    init(status: LocationAuthorizationStatus = .notDetermined,
         statusAfterRequest: LocationAuthorizationStatus = .authorizedWhenInUse) {
        authorizationStatus = status
        self.statusAfterRequest = statusAfterRequest
    }

    func requestWhenInUseAuthorization() async -> LocationAuthorizationStatus {
        requestCount += 1
        authorizationStatus = statusAfterRequest
        return authorizationStatus
    }

    func currentLocation() async -> GeoCoordinate? {
        locationFetchCount += 1
        return nil
    }
}
