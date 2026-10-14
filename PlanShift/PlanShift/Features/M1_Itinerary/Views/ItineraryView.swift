// Module: M1 – placeholder for M1-01 Itinerary.

import SwiftUI

/// M1-01 Itinerary. Placeholder: the M1 owner replaces this with the real screen.
struct ItineraryView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        VStack(spacing: 16) {
            Text("M1-01").font(.largeTitle.bold())
            Text("Itinerary").font(.title2)
            Button("Activity Detail") {
                router.itineraryPath.append(.activityDetail(activityId: PreviewSamples.coastalWalk.id))
            }
            Button("Add Activity") { router.itineraryPath.append(.activityForm) }
            Button("Empty State") { router.itineraryPath.append(.emptyState) }
            Button("Create Trip") { router.itineraryPath.append(.createTrip) }
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .foregroundStyle(AppColors.textPrimary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.backgroundGradient)
        .safeAreaInset(edge: .bottom) {
            if router.showsUpdatedItineraryBanner {
                UpdatedItineraryBanner()
            }
        }
    }
}

#Preview {
    NavigationStack { ItineraryView() }
        .environment(AppRouter())
}
