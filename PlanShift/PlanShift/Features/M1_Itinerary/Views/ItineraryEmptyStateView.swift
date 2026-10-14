// Module: M1 – placeholder for M1-05 Empty State.

import SwiftUI

/// M1-05 Empty State. Placeholder: the M1 owner replaces this with the real screen.
struct ItineraryEmptyStateView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        VStack(spacing: 16) {
            Text("M1-05").font(.largeTitle.bold())
            Text("Empty State").font(.title2)
            Button("Create Trip") { router.itineraryPath.append(.createTrip) }
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .foregroundStyle(AppColors.textPrimary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.backgroundGradient)
    }
}

#Preview {
    ItineraryEmptyStateView()
        .environment(AppRouter())
}
