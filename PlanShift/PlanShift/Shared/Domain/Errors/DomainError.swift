// Module: Shared – domain error.

import Foundation

/// Business-rule errors thrown by use cases and repositories.
/// Views show `error.localizedDescription` to the user.
nonisolated enum DomainError: LocalizedError, Equatable, Sendable {
    case invalidTimeRange
    case emptyName
    case timeConflict
    case invalidTripDates
    case noMatchingAlternatives
    case activityNotFound
    case duplicateBackup
    case locationDenied
    case persistenceFailure

    var errorDescription: String? {
        switch self {
        case .invalidTimeRange: "The end time must be after the start time."
        case .emptyName: "Please enter a name."
        case .timeConflict: "This overlaps another activity on the same day."
        case .invalidTripDates: "The trip must end on or after its start date."
        case .noMatchingAlternatives: "No alternatives match your filters. Try widening them."
        case .activityNotFound: "This activity could not be found."
        case .duplicateBackup: "This place is already saved as a backup."
        case .locationDenied: "Location access is off. You can turn it on in Settings."
        case .persistenceFailure: "Your data could not be saved. Please try again."
        }
    }
}
