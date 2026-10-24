import Foundation

@MainActor
struct GetLocationStatus {
    let location: any LocationProviding

    var status: LocationAuthorizationStatus { location.authorizationStatus }

    /// Reading permission never requests access or fetches a position.
    func execute() throws -> LocationAuthorizationStatus {
        let current = status
        guard !current.isBlocked else { throw DomainError.locationDenied }
        return current
    }
}
