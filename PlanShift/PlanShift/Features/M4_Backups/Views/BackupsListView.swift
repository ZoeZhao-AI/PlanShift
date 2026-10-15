// Module: M4 – placeholder for M4-01 Backups List.

import SwiftUI

/// M4-01 Backups List. Placeholder: the M4 owner replaces this with the real screen.
struct BackupsListView: View {
    @Environment(AppRouter.self) private var router
    @State private var isShowingDuplicateToast = false

    /// Placeholder backup built from the preview samples.
    private let sampleBackup = BackupOption(
        tripId: PreviewSamples.trip.id,
        content: .place(PreviewSamples.queenVictoriaBuilding),
        dayDate: PreviewSamples.coastalWalk.date
    )

    var body: some View {
        VStack(spacing: 16) {
            Text("M4-01").font(.largeTitle.bold())
            Text("Backups List").font(.title2)
            Button("Use a Backup") { router.present(.useBackup(backup: sampleBackup)) }
            NavigationLink("Empty State") { BackupsEmptyStateView() }
            Button("Duplicate Toast") { isShowingDuplicateToast.toggle() }
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
    NavigationStack { BackupsListView() }
        .environment(AppRouter())
}
