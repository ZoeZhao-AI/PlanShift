// Module: M3 – placeholder for M3-02 Updated Itinerary Banner.

import SwiftUI

/// M3-02 Updated Itinerary Banner (shown at the bottom of M1-01 after a replace).
/// Placeholder: the M3 owner replaces this with the real banner.
struct UpdatedItineraryBanner: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        VStack(spacing: 8) {
            Text("M3-02").font(.largeTitle.bold())
            Text("Updated Itinerary Banner").font(.title2)
            Button("Undo") { router.showsUpdatedItineraryBanner = false }
                .buttonStyle(.bordered)
                .controlSize(.large)
        }
        .foregroundStyle(AppColors.textPrimary)
        .frame(maxWidth: .infinity)
        .padding()
        .background(.regularMaterial)
    }
}

#Preview {
    UpdatedItineraryBanner()
        .environment(AppRouter())
}
