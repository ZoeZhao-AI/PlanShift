// Module: M2 – placeholder for M2-01 Select Disruption.

import SwiftUI

/// M2-01 Select Disruption (first screen of the disruption sheet).
/// Placeholder: the M2 owner replaces this with the real screen.
struct SelectDisruptionView: View {
    let activity: ItineraryActivity

    @Environment(AppRouter.self) private var router

    var body: some View {
        VStack(spacing: 16) {
            Text("M2-01").font(.largeTitle.bold())
            Text("Select Disruption").font(.title2)
            Text(activity.name).foregroundStyle(AppColors.textSecondary)
            NavigationLink("Preference Filters") {
                PreferenceFiltersView(activity: activity)
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .foregroundStyle(AppColors.textPrimary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.backgroundGradient)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { router.dismissSheet() }
            }
        }
    }
}

#Preview {
    NavigationStack { SelectDisruptionView(activity: PreviewSamples.coastalWalk) }
        .environment(AppRouter())
}
