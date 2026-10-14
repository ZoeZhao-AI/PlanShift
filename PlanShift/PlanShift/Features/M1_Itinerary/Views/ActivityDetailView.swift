// Module: M1 – placeholder for M1-03 Activity Detail.

import SwiftUI

/// M1-03 Activity Detail (also opened by widget deep links).
/// Placeholder: the M1 owner replaces this with the real screen.
struct ActivityDetailView: View {
    let activityId: UUID

    @Environment(AppRouter.self) private var router
    @State private var isShowingDeleteConfirmation = false

    /// Placeholder lookup in the preview samples; the real screen loads the activity.
    private var activity: ItineraryActivity {
        PreviewSamples.activities.first { $0.id == activityId } ?? PreviewSamples.coastalWalk
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("M1-03").font(.largeTitle.bold())
            Text("Activity Detail").font(.title2)
            Text(activity.name).foregroundStyle(AppColors.textSecondary)
            Button("Plan Disrupted") { router.present(.disruptionFlow(activity: activity)) }
            Button("Edit") { router.itineraryPath.append(.activityForm) }
            Button("Delete", role: .destructive) { isShowingDeleteConfirmation = true }
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .foregroundStyle(AppColors.textPrimary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.backgroundGradient)
        .deleteConfirmationAlert(isPresented: $isShowingDeleteConfirmation) {
            router.itineraryPath.removeLast()
        }
    }
}

#Preview {
    NavigationStack { ActivityDetailView(activityId: PreviewSamples.coastalWalk.id) }
        .environment(AppRouter())
}
