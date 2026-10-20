// Module: Shared – root view with the 3 tabs and sheets.

import SwiftUI

/// The app's root: one tab per area, and sheets driven by `AppRouter.activeSheet`.
struct RootView: View {
    @Environment(AppRouter.self) private var router
    @State private var replaceViewModel: ReplaceViewModel
    @State private var backupsListViewModel: BackupsListViewModel

    private let saveBackup: SaveBackupUseCase
    private let fetchDayActivities: FetchDayActivitiesUseCase
    /// Temporary: M1 does not store trips yet, so Backups and Use backup use the sample trip.
    private let currentTrip = PreviewSamples.trip

    init(persistence: PersistenceController) {
        // Temporary until M1's Core Data activity repository is available.
        let activityRepository = MockActivityRepository(
            activities: [PreviewSamples.coastalWalk]
        )
        // One backup repository for the whole app, so M2, M3 and M4 see the same backups.
        let backupRepository = CoreDataBackupRepository(container: persistence.container)
        saveBackup = SaveBackupUseCase(repository: backupRepository)
        fetchDayActivities = FetchDayActivitiesUseCase(repository: activityRepository)
        _backupsListViewModel = State(
            initialValue: BackupsListViewModel(
                fetchBackups: FetchBackupsUseCase(repository: backupRepository),
                removeBackup: RemoveBackupUseCase(repository: backupRepository)
            )
        )

        _replaceViewModel = State(
            initialValue: ReplaceViewModel(
                replaceActivity: ReplaceActivityUseCase(
                    activityRepository: activityRepository,
                    backupRepository: backupRepository
                ),
                undoReplace: UndoReplaceUseCase(
                    activityRepository: activityRepository
                )
            )
        )
    }

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
                BackupsListView(viewModel: backupsListViewModel, trip: currentTrip)
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
                    RecommendationFlowView(activity: activity, backups: saveBackup)
                case .replaceConfirmation(let original, let alternative):
                    ReplaceConfirmationView(original: original, alternative: alternative)
                case .useBackup(let backup):
                    UseBackupView(
                        backup: backup,
                        viewModel: UseBackupViewModel(backup: backup, fetchDayActivities: fetchDayActivities),
                        trip: currentTrip
                    )
                }
            }
        }
        .onOpenURL { url in
            router.handle(url: url)
        }
        .environment(replaceViewModel)
    }
}

#Preview {
    if let persistence = try? PersistenceController(inMemory: true) {
        RootView(persistence: persistence)
            .environment(AppRouter())
    }
}
