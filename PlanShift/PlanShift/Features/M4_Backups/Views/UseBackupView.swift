// Module: M4 – placeholder for M4-02 Use a Backup.

import SwiftUI

/// M4-02 Use a Backup. Placeholder: the M4 owner replaces this with the real screen.
struct UseBackupView: View {
    let backup: BackupOption

    @Environment(AppRouter.self) private var router

    var body: some View {
        VStack(spacing: 16) {
            Text("M4-02").font(.largeTitle.bold())
            Text("Use a Backup").font(.title2)
            Text(backup.place.name).foregroundStyle(AppColors.textSecondary)
            Button("Replace an Activity") {
                router.present(.replaceConfirmation(original: PreviewSamples.coastalWalk, alternative: backup.place))
            }
            Button("Cancel") { router.dismissSheet() }
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .foregroundStyle(AppColors.textPrimary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.backgroundGradient)
    }
}

#Preview {
    UseBackupView(backup: BackupOption(tripId: PreviewSamples.trip.id, place: PreviewSamples.australianMuseum, dayDate: .now))
        .environment(AppRouter())
}
