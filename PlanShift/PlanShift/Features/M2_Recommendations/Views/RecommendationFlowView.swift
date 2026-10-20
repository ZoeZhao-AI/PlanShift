//
//  RecommendationFlowView.swift
//  PlanShift
//
//  Created by Van Dao Le on 15/10/2026.
//

// Module: M2 – the disruption sheet (M2-01 → M2-04): connects the screens to the flow view model.

import SwiftUI

/// Root of the disruption sheet. Owns the `RecommendationFlowViewModel` and feeds the UI-only screens,
/// so none of them needs to know about use cases or repositories.
///
/// Bookmarks go through `backups` (M4's `SaveBackupUseCase`), so they land in the Backups tab.
/// Location comes from `CoreLocationService` (When In Use, one fix, asked only after the pre-prompt).
struct RecommendationFlowView: View {
    @State private var model: RecommendationFlowViewModel
    @State private var showsFilters = false

    init(activity: ItineraryActivity, backups: BackupSaving) {
        _model = State(initialValue: .live(for: activity, backups: backups))
    }

    var body: some View {
        SelectDisruptionView(
            activity: model.activity,
            dayLabel: model.dayLabel,
            selected: model.disruption,
            onSelect: { disruption in
                model.select(disruption)
                showsFilters = true
            }
        )
        .task { await model.loadTripContext() }
        .navigationDestination(isPresented: $showsFilters) {
            if let disruption = model.disruption {
                FiltersStep(model: model, disruption: disruption)
            }
        }
    }
}

// MARK: - Steps
//
// Each step reads the observable model in its own body so changes invalidate the pushed screen,
// including when a search finishes after the location sheet closes.

/// M2-02.
private struct FiltersStep: View {
    @Bindable var model: RecommendationFlowViewModel
    let disruption: Disruption

    var body: some View {
        PreferenceFiltersView(
            activity: model.activity,
            disruption: disruption,
            filters: $model.filters,
            originDescription: model.originDescription,
            isLoading: model.phase == .loading,
            showsLocationPrompt: model.isShowingLocationPrePrompt,
            onReset: model.resetFilters,
            onShowAlternatives: { Task { await model.showAlternatives() } },
            onAllowLocation: { Task { await model.allowLocation() } },
            onNotNow: { Task { await model.declineLocation() } },
            onLocationPromptDismissed: { Task { await model.locationPrePromptDismissed() } }
        )
        .navigationDestination(isPresented: $model.showsResults) {
            ResultsStep(model: model, disruption: disruption)
        }
    }
}

/// M2-03, plus its empty (M2-04), loading and error states.
private struct ResultsStep: View {
    let model: RecommendationFlowViewModel
    let disruption: Disruption
    @Environment(AppRouter.self) private var router

    var body: some View {
        RankedAlternativesView(
            activity: model.activity,
            filters: model.filters,
            disruption: disruption,
            state: screenState,
            savedIds: model.savedPlaceIds,
            busyIds: model.busyPlaceIds,
            showsLocationBanner: model.showsLocationDeniedBanner,
            originFootnote: originFootnote,
            toast: model.toast,
            onBookmark: { alternative in Task { await model.bookmark(alternative) } },
            onTryAgain: { Task { await model.search() } },
            onToastAction: {
                model.dismissToast()
                router.dismissSheet()
                router.selectedTab = .backups
            }
        )
        .task(id: model.toast) {
            guard let toast = model.toast else { return }
            do {
                try await Task.sleep(for: .seconds(4))
            } catch {
                return
            }
            // A cancelled timer must not clear the next bookmark's confirmation.
            guard model.toast?.id == toast.id else { return }
            model.dismissToast()
        }
    }

    private var screenState: AlternativesScreenState {
        switch model.phase {
        case .idle, .loading: .loading
        case .results(let alternatives): .results(alternatives)
        case .empty: .empty
        case .failed(let message): .failed(message)
        }
    }

    private var originFootnote: String {
        switch model.origin.source {
        case .device: "Distances are approximate, measured in a straight line from your location. Walking times are estimates."
        case .plannedActivity: "Distances are approximate, measured in a straight line from your planned activity. Walking times are estimates."
        case .unavailable: "Distances aren't available because this activity has no location."
        }
    }
}

// MARK: - Wiring

extension RecommendationFlowViewModel {
    /// A view model on the bundled places, the given backup saver and the system location service.
    static func live(for activity: ItineraryActivity, backups: BackupSaving) -> RecommendationFlowViewModel {
        RecommendationFlowViewModel(
            activity: activity,
            getAlternatives: GetAlternativesUseCase(places: BundledPlaceRepository()),
            backups: backups,
            location: CoreLocationService()
        )
    }
}
