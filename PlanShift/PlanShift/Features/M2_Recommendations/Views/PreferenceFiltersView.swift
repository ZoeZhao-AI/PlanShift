// Module: M2 – placeholder for M2-02 Preference Filters.

import SwiftUI

/// M2-02 Preference Filters. Placeholder: the M2 owner replaces this with the real screen.
struct PreferenceFiltersView: View {
    let activity: ItineraryActivity

    var body: some View {
        VStack(spacing: 16) {
            Text("M2-02").font(.largeTitle.bold())
            Text("Preference Filters").font(.title2)
            NavigationLink("Ranked Alternatives") { RankedAlternativesView(activity: activity) }
            NavigationLink("No Results") { NoResultsView() }
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .foregroundStyle(AppColors.textPrimary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.backgroundGradient)
    }
}

#Preview {
    NavigationStack { PreferenceFiltersView(activity: PreviewSamples.coastalWalk) }
        .environment(AppRouter())
}
