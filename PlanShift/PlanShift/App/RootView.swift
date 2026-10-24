// Module: Shared – root view with the 3 tabs and sheets.

import SwiftUI

/// The app's root: one tab per area, and sheets driven by `AppRouter.activeSheet`.
struct RootView: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.scenePhase) private var scenePhase
    @State private var replaceViewModel: ReplaceViewModel
    @State private var backupsListViewModel: BackupsListViewModel

    private let saveBackup: SaveBackupUseCase
    private let fetchDayActivities: FetchDayActivitiesUseCase
    /// One trip and one activity repository for the whole app, so M1 writes what M2, M3 and M4 read.
    private let tripRepository: any TripRepository
    private let activityRepository: any ActivityRepository

    init(persistence: PersistenceController) {
        let tripRepository = CoreDataTripRepository(container: persistence.container)
        let activityRepository = CoreDataActivityRepository(container: persistence.container)
        self.tripRepository = tripRepository
        self.activityRepository = activityRepository
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
                ItineraryView(tripRepository: tripRepository, activityRepository: activityRepository)
                    .navigationDestination(for: ItineraryRoute.self) { route in
                        switch route {
                        case .activityDetail(let activityId):
                            ActivityDetailView(
                                activityId: activityId,
                                repository: activityRepository,
                                tripRepository: tripRepository
                            )
                        case .activityForm:
                            ActivityFormView(tripRepository: tripRepository, activityRepository: activityRepository)
                        case .emptyState: ItineraryEmptyStateView()
                        case .createTrip: CreateTripView(repository: tripRepository)
                        }
                    }
            }
            .tabItem { Label("Itinerary", systemImage: "calendar") }
            .tag(AppTab.itinerary)

            NavigationStack {
                CurrentTripView(trips: tripRepository, reloadOn: router.selectedTab) { trip in
                    BackupsListView(viewModel: backupsListViewModel, trip: trip)
                }
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
                    RecommendationFlowView(activity: activity, backups: saveBackup, trips: tripRepository)
                case .replaceConfirmation(let original, let alternative, let restoring):
                    ReplaceConfirmationView(original: original, alternative: alternative, restoring: restoring)
                case .useBackup(let backup):
                    CurrentTripView(trips: tripRepository, reloadOn: backup.id) { trip in
                        UseBackupView(
                            backup: backup,
                            viewModel: UseBackupViewModel(backup: backup, fetchDayActivities: fetchDayActivities),
                            trip: trip
                        )
                    }
                }
            }
        }
        .onOpenURL { url in
            router.handle(url: url)
        }
        .onChange(of: scenePhase) {
            if scenePhase == .background {
                WidgetTimelineReloader().requestReload()
            }
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
