import CoreLocation
import Observation
import UIKit

/// Foreground permission and one-shot location only. Positions are never persisted.
@MainActor
@Observable
final class CoreLocationService: NSObject, LocationProviding, CLLocationManagerDelegate {
    static let shared = CoreLocationService()

    private(set) var authorizationStatus: LocationAuthorizationStatus
    @ObservationIgnored private let manager: CLLocationManager
    @ObservationIgnored private var permissionRequests: [UUID: CheckedContinuation<LocationAuthorizationStatus, Never>] = [:]
    @ObservationIgnored private var positionRequests: [UUID: CheckedContinuation<GeoCoordinate?, Never>] = [:]
    @ObservationIgnored private var positionTimeout: Task<Void, Never>?

    override init() {
        let manager = CLLocationManager()
        self.manager = manager
        authorizationStatus = Self.mapAuthorization(manager.authorizationStatus)
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        NotificationCenter.default.addObserver(
            self, selector: #selector(becameActive),
            name: UIApplication.didBecomeActiveNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(enteredBackground),
            name: UIApplication.didEnterBackgroundNotification, object: nil
        )
    }

    func refreshAuthorizationStatus() async {
        // Core Location's global service check can block; keep it off the UI thread.
        let enabled = await Task.detached {
            CLLocationManager.locationServicesEnabled()
        }.value
        authorizationStatus = Self.mapAuthorization(manager.authorizationStatus, servicesEnabled: enabled)
        if authorizationStatus != .notDetermined {
            finishPermissionRequests()
        }
        if !authorizationStatus.isAuthorized {
            finishPositionRequests(with: nil)
        }
    }

    func requestWhenInUseAuthorization() async -> LocationAuthorizationStatus {
        await refreshAuthorizationStatus()
        guard !Task.isCancelled, UIApplication.shared.applicationState == .active,
              authorizationStatus == .notDetermined else {
            return authorizationStatus
        }
        let id = UUID()
        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                guard !Task.isCancelled else {
                    continuation.resume(returning: authorizationStatus)
                    return
                }
                permissionRequests[id] = continuation
                if permissionRequests.count == 1 {
                    manager.requestWhenInUseAuthorization()
                }
            }
        } onCancel: {
            Task { @MainActor [weak self] in
                guard let self else { return }
                permissionRequests.removeValue(forKey: id)?.resume(returning: authorizationStatus)
            }
        }
    }

    func currentLocation() async -> GeoCoordinate? {
        await refreshAuthorizationStatus()
        guard !Task.isCancelled, UIApplication.shared.applicationState == .active,
              authorizationStatus.isAuthorized else { return nil }
        let id = UUID()
        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                guard !Task.isCancelled else {
                    continuation.resume(returning: nil)
                    return
                }
                positionRequests[id] = continuation
                guard positionRequests.count == 1 else { return }
                manager.requestLocation()
                positionTimeout = Task { [weak self] in
                    do { try await Task.sleep(for: .seconds(10)) }
                    catch { return }
                    self?.finishPositionRequests(with: nil)
                }
            }
        } onCancel: {
            Task { @MainActor [weak self] in
                guard let self else { return }
                positionRequests.removeValue(forKey: id)?.resume(returning: nil)
                if positionRequests.isEmpty { finishPositionRequests(with: nil) }
            }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor [weak self] in await self?.refreshAuthorizationStatus() }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last { location in
            location.horizontalAccuracy >= 0 && abs(location.timestamp.timeIntervalSinceNow) <= 60
        }
        let coordinate = location.map {
            GeoCoordinate(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude)
        }
        Task { @MainActor [weak self] in
            guard let self else { return }
            let result = authorizationStatus.isAuthorized && coordinate?.isValid == true ? coordinate : nil
            finishPositionRequests(with: result)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor [weak self] in self?.finishPositionRequests(with: nil) }
    }

    nonisolated static func mapAuthorization(
        _ status: CLAuthorizationStatus,
        servicesEnabled: Bool = true
    ) -> LocationAuthorizationStatus {
        guard servicesEnabled else { return .servicesDisabled }
        return switch status {
        case .notDetermined: .notDetermined
        case .denied: .denied
        case .restricted: .restricted
        // Existing Always permission is usable, but this app never requests it.
        case .authorizedAlways, .authorizedWhenInUse: .authorizedWhenInUse
        @unknown default: .restricted
        }
    }

    @objc private func becameActive() {
        Task { [weak self] in await self?.refreshAuthorizationStatus() }
    }

    @objc private func enteredBackground() {
        finishPermissionRequests()
        finishPositionRequests(with: nil)
    }

    private func finishPermissionRequests() {
        let requests = permissionRequests.values
        permissionRequests.removeAll()
        for request in requests { request.resume(returning: authorizationStatus) }
    }

    private func finishPositionRequests(with coordinate: GeoCoordinate?) {
        positionTimeout?.cancel()
        positionTimeout = nil
        manager.stopUpdatingLocation()
        let requests = positionRequests.values
        positionRequests.removeAll()
        for request in requests { request.resume(returning: coordinate) }
    }
}
