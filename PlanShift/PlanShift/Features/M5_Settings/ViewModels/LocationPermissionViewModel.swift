import Foundation
import Observation

@MainActor
@Observable
final class LocationPermissionViewModel {
    // Avoid Swift 6.2's isolated-deinit back-deployment crash during synchronous teardown.
    nonisolated deinit {}

    private let location: any LocationProviding
    private let getStatus: GetLocationStatus
    private let openSettingsAction: @MainActor () async -> Bool
    private(set) var isRequesting = false
    private(set) var error: DomainError?
    private(set) var settingsError: String?

    // Observation also tracks the live service's authorizationStatus property.
    var status: LocationAuthorizationStatus { getStatus.status }

    init(
        location: any LocationProviding,
        openSettings: @escaping @MainActor () async -> Bool = { await LocationSettingsOpener.open() }
    ) {
        self.location = location
        getStatus = GetLocationStatus(location: location)
        openSettingsAction = openSettings
    }

    func allowLocation() async {
        guard !isRequesting, status == .notDetermined else { return }
        isRequesting = true
        defer { isRequesting = false }
        _ = await location.requestWhenInUseAuthorization()
        guard !Task.isCancelled else { return }
        refresh()
    }

    func refresh() {
        do {
            _ = try getStatus.execute()
            error = nil
        } catch {
            self.error = error as? DomainError
        }
    }

    func openSettings() async {
        settingsError = await openSettingsAction() ? nil
            : "Please open Settings and select PlanShift to review location access."
    }
}
