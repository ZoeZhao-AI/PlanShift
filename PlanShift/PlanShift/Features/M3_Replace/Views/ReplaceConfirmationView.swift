// Module: M3 – placeholder for M3-01 Replace Confirmation.

import SwiftUI

/// M3-01 Replace Confirmation. Placeholder: the M3 owner replaces this with the real screen.
struct ReplaceConfirmationView: View {
    let original: ItineraryActivity
    let alternative: Place

    @Environment(AppRouter.self) private var router

    var body: some View {
        VStack(spacing: 16) {
            Text("M3-01").font(.largeTitle.bold())
            Text("Replace Confirmation").font(.title2)
            Text("\(original.name) → \(alternative.name)").foregroundStyle(AppColors.textSecondary)
            Button("Confirm") { router.didReplaceActivity() }
            Button("Cancel") { router.dismissSheet() }
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .foregroundStyle(AppColors.textPrimary)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.backgroundGradient)
    }
}

#Preview {
    ReplaceConfirmationView(original: PreviewSamples.coastalWalk, alternative: PreviewSamples.australianMuseum)
        .environment(AppRouter())
}
