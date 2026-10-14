// Module: M2 – placeholder for M2-03 Ranked Alternatives.

import SwiftUI

/// M2-03 Ranked Alternatives. Placeholder: the M2 owner replaces this with the real screen.
struct RankedAlternativesView: View {
    let activity: ItineraryActivity

    @Environment(AppRouter.self) private var router
    @State private var isShowingDuplicateToast = false

    var body: some View {
        VStack(spacing: 16) {
            Text("M2-03").font(.largeTitle.bold())
            Text("Ranked Alternatives").font(.title2)
            Button("Replace Activity") {
                router.present(.replaceConfirmation(original: activity, alternative: PreviewSamples.australianMuseum))
            }
            Button("Save as Backup") { isShowingDuplicateToast = true }
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .foregroundStyle(AppColors.textPrimary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.backgroundGradient)
        .safeAreaInset(edge: .bottom) {
            if isShowingDuplicateToast {
                DuplicateBackupToast()
            }
        }
    }
}

#Preview {
    NavigationStack { RankedAlternativesView(activity: PreviewSamples.coastalWalk) }
        .environment(AppRouter())
}
