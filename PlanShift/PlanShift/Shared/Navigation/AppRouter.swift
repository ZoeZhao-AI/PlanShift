// Module: Shared – navigation.

import Foundation
import Observation

/// The three tabs of the root TabView.
enum AppTab: Hashable {
    case itinerary
    case backups
    case settings
}

/// Screens shown as a sheet on top of the tabs.
enum SheetRoute: Identifiable, Hashable {
    case disruptionFlow(activity: ItineraryActivity)                        // M2-01 → M2-04
    case replaceConfirmation(original: ItineraryActivity, alternative: Place) // M3-01
    case useBackup(backup: BackupOption)                                    // M4-02

    var id: String {
        switch self {
        case .disruptionFlow(let activity): "disruption-\(activity.id)"
        case .replaceConfirmation(let original, let alternative): "replace-\(original.id)-\(alternative.id)"
        case .useBackup(let backup): "useBackup-\(backup.id)"
        }
    }
}

/// Screens pushed inside the Itinerary tab.
enum ItineraryRoute: Hashable {
    case activityDetail(activityId: UUID) // M1-03
    case activityForm                     // M1-02
    case emptyState                       // M1-05
    case createTrip                       // M1-06
}

/// All navigation state in one place. Any screen can read it with
/// `@Environment(AppRouter.self) private var router` and change it, e.g.
/// `router.present(.disruptionFlow(activity: activity))`.
@MainActor
@Observable
final class AppRouter {
    static let urlScheme = "planshift"

    var selectedTab: AppTab = .itinerary
    var activeSheet: SheetRoute?
    var itineraryPath: [ItineraryRoute] = []
    /// Shows the M3-02 "Itinerary updated" banner on the Itinerary tab.
    var showsUpdatedItineraryBanner = false

    func present(_ sheet: SheetRoute) {
        activeSheet = sheet
    }

    func dismissSheet() {
        activeSheet = nil
    }

    /// After M3-01 confirms: close the sheet, go back to the itinerary and show M3-02.
    func didReplaceActivity() {
        activeSheet = nil
        selectedTab = .itinerary
        itineraryPath = []
        showsUpdatedItineraryBanner = true
    }

    /// Handles widget deep links: planshift://activity/<uuid> opens M1-03.
    /// Returns false if the URL is not understood.
    @discardableResult
    func handle(url: URL) -> Bool {
        guard url.scheme == Self.urlScheme,
              url.host() == "activity",
              let idText = url.pathComponents.dropFirst().first,
              let activityId = UUID(uuidString: idText) else {
            return false
        }
        activeSheet = nil
        selectedTab = .itinerary
        itineraryPath = [.activityDetail(activityId: activityId)]
        return true
    }
}
