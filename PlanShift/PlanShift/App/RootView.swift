// Module: Shared – root view with the 3 tabs and sheets.

import SwiftUI

/// The app's root: one tab per area, and sheets driven by `AppRouter.activeSheet`.
struct RootView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        // @Bindable lets us create bindings ($router.selectedTab) to the router.
        @Bindable var router = router

        TabView(selection: $router.selectedTab) {
            NavigationStack(path: $router.itineraryPath) {
                ItineraryView()
                    .navigationDestination(for: ItineraryRoute.self) { route in
                        switch route {
                        case .activityDetail(let activityId): ActivityDetailView(activityId: activityId)
                        case .activityForm: ActivityFormView()
                        case .emptyState: ItineraryEmptyStateView()
                        case .createTrip: CreateTripView()
                        }
                    }
            }
            .tabItem { Label("Itinerary", systemImage: "calendar") }
            .tag(AppTab.itinerary)

            NavigationStack {
                BackupsListView()
            }
            .tabItem { Label("Backups", systemImage: "bookmark") }
            .tag(AppTab.backups)

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("Settings", systemImage: "gearshape") }
            .tag(AppTab.settings)
        }
        .tint(AppColors.primary)
        .sheet(item: $router.activeSheet) { route in
            NavigationStack {
                switch route {
                case .disruptionFlow(let activity):
                    RecommendationFlowView(activity: activity)
                case .replaceConfirmation(let original, let alternative):
                    ReplaceConfirmationView(original: original, alternative: alternative)
                case .useBackup(let backup):
                    UseBackupView(backup: backup)
                }
            }
        }
        .onOpenURL { url in
            router.handle(url: url)
        }
    }
}

#Preview {
    RootView()
        .environment(AppRouter())
}
