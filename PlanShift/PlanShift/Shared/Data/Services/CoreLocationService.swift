// Module: Shared – data layer (M5): LocationProviding backed by CoreLocation.

import CoreLocation
import Foundation

/// The slice of `CLLocationManager` that `CoreLocationService` needs.
/// Tests drive a fake, so no system permission dialog or real GPS is involved.
@MainActor
protocol LocationManaging: AnyObject {
    var authorizationStatus: CLAuthorizationStatus { get }
    /// The system's cached position, if any (it may be old).
    var lastKnownLocation: CLLocation? { get }

    var onAuthorizationChange: (() -> Void)? { get set }
    var onLocations: (([CLLocation]) -> Void)? { get set }
    var onFailure: ((Error) -> Void)? { get set }

    func requestWhenInUseAuthorization()
    func requestLocation()
}

/// The real `CLLocationManager`, with its delegate callbacks turned into closures on the main actor.
final class SystemLocationManager: NSObject, LocationManaging, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    var onAuthorizationChange: (() -> Void)?
    var onLocations: (([CLLocation]) -> Void)?
    var onFailure: ((Error) -> Void)?

    var authorizationStatus: CLAuthorizationStatus { manager.authorizationStatus }
    var lastKnownLocation: CLLocation? { manager.location }

    override init() {
        super.init()
        manager.delegate = self
        // Straight-line distances to places a few km away do not need GPS precision, and a coarser
        // fix is quicker and uses less battery.
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestWhenInUseAuthorization() { manager.requestWhenInUseAuthorization() }
    func requestLocation() { manager.requestLocation() }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in self.onAuthorizationChange?() }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in self.onLocations?(locations) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in self.onFailure?(error) }
    }
}

/// Foreground "When In Use" location: the permission status and one position fix, nothing else.
///
/// - Asks iOS for permission only when `requestWhenInUseAuthorization()` is called (after the app's own
///   pre-prompt), and never asks again once the user has decided.
/// - Never tracks: one fix per call, nothing is stored, nothing leaves the device.
/// - `currentLocation()` never throws; any problem (no permission, no signal, timeout) is `nil`,
///   and the caller falls back to the planned activity's location.
@MainActor
final class CoreLocationService: LocationProviding {
    private let manager: LocationManaging
    private let timeout: Duration
    private let maxFixAge: TimeInterval
    private let now: @Sendable () -> Date

    private var authorizationWaiters: [CheckedContinuation<LocationAuthorizationStatus, Never>] = []
    private var fixWaiters: [UUID: CheckedContinuation<GeoCoordinate?, Never>] = [:]

    init(
        manager: LocationManaging? = nil,
        timeout: Duration = .seconds(10),
        maxFixAge: TimeInterval = 120,
        now: @escaping @Sendable () -> Date = { .now }
    ) {
        let manager = manager ?? SystemLocationManager()
        self.manager = manager
        self.timeout = timeout
        self.maxFixAge = maxFixAge
        self.now = now

        manager.onAuthorizationChange = { [weak self] in self?.authorizationChanged() }
        manager.onLocations = { [weak self] locations in self?.received(locations) }
        manager.onFailure = { [weak self] _ in self?.finishAllFixes(with: nil) }
    }

    // MARK: - LocationProviding

    var authorizationStatus: LocationAuthorizationStatus {
        Self.status(from: manager.authorizationStatus)
    }

    func requestWhenInUseAuthorization() async -> LocationAuthorizationStatus {
        guard authorizationStatus == .notDetermined else { return authorizationStatus }
        return await withCheckedContinuation { continuation in
            authorizationWaiters.append(continuation)
            // Ask the system once, even if several callers are waiting.
            if authorizationWaiters.count == 1 {
                manager.requestWhenInUseAuthorization()
            }
        }
    }

    func currentLocation() async -> GeoCoordinate? {
        guard authorizationStatus.isAuthorized else { return nil }

        // A recent system fix is good enough for rough distances and saves a request.
        if let cached = manager.lastKnownLocation, isFresh(cached), let coordinate = Self.coordinate(from: cached) {
            return coordinate
        }

        let id = UUID()
        return await withCheckedContinuation { continuation in
            let isFirst = fixWaiters.isEmpty
            fixWaiters[id] = continuation
            if isFirst {
                manager.requestLocation()
            }
            // Give up after `timeout` so a missing signal never leaves the screen waiting.
            Task { [weak self, timeout] in
                try? await Task.sleep(for: timeout)
                self?.finishFix(id: id, with: nil)
            }
        }
    }

    // MARK: - Delegate events

    private func authorizationChanged() {
        let status = authorizationStatus
        // CoreLocation also reports the initial "not determined"; wait for the user's real answer.
        guard status != .notDetermined else { return }
        let waiters = authorizationWaiters
        authorizationWaiters = []
        for waiter in waiters { waiter.resume(returning: status) }
    }

    private func received(_ locations: [CLLocation]) {
        // Newest valid fix wins.
        let coordinate = locations
            .sorted { $0.timestamp > $1.timestamp }
            .lazy
            .compactMap { Self.coordinate(from: $0) }
            .first
        finishAllFixes(with: coordinate)
    }

    private func finishAllFixes(with coordinate: GeoCoordinate?) {
        let waiters = fixWaiters
        fixWaiters = [:]
        for waiter in waiters.values { waiter.resume(returning: coordinate) }
    }

    private func finishFix(id: UUID, with coordinate: GeoCoordinate?) {
        fixWaiters.removeValue(forKey: id)?.resume(returning: coordinate)
    }

    // MARK: - Helpers

    private func isFresh(_ location: CLLocation) -> Bool {
        now().timeIntervalSince(location.timestamp) <= maxFixAge
    }

    /// Maps iOS's status. "Always" counts as usable (we only ever ask for When In Use, but the user may
    /// have granted more in Settings); anything unknown is treated as denied.
    nonisolated static func status(from status: CLAuthorizationStatus) -> LocationAuthorizationStatus {
        switch status {
        case .notDetermined: .notDetermined
        case .restricted: .restricted
        case .denied: .denied
        case .authorizedWhenInUse, .authorizedAlways: .authorizedWhenInUse
        @unknown default: .denied
        }
    }

    /// A usable coordinate, or `nil` for an invalid fix (negative accuracy means "no valid position").
    nonisolated static func coordinate(from location: CLLocation) -> GeoCoordinate? {
        guard location.horizontalAccuracy >= 0 else { return nil }
        let coordinate = GeoCoordinate(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        return coordinate.isValid ? coordinate : nil
    }
}
