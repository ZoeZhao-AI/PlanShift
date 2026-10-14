// Module: M1 – placeholder for M1-06 Create Trip.

import SwiftUI

/// M1-06 Create Trip. Placeholder: the M1 owner replaces this with the real screen.
struct CreateTripView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        VStack(spacing: 16) {
            Text("M1-06").font(.largeTitle.bold())
            Text("Create Trip").font(.title2)
            Button("Create") { router.itineraryPath = [] }
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .foregroundStyle(AppColors.textPrimary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.backgroundGradient)
    }
}

#Preview {
    CreateTripView()
        .environment(AppRouter())
}
