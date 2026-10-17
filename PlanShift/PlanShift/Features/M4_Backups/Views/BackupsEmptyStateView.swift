// Module: M4 – M4-03 Empty State: shown on the Backups tab when the trip has no backups.

import SwiftUI

/// M4-03. Explains what backups are and how to save one.
struct BackupsEmptyStateView: View {
    let tripName: String

    /// Grows with Dynamic Type so the cloud always stays inside its circle.
    @ScaledMetric(relativeTo: .largeTitle) private var circleSize: CGFloat = 160

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text(tripName)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                illustration
                    .padding(.top, 24)

                VStack(spacing: 8) {
                    Text("No backups yet")
                        .font(.title2.bold())
                        .foregroundStyle(AppColors.textPrimary)
                    Text("Save alternatives so you're ready if plans change.")
                        .font(.body)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .multilineTextAlignment(.center)

                hintCard
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.backgroundGradient)
        .navigationTitle("Backups")
    }

    /// A cloud with a bookmark, made from SF Symbols.
    private var illustration: some View {
        ZStack {
            Circle()
                .fill(AppColors.primary.opacity(0.12))
                .frame(width: circleSize, height: circleSize)
            Image(systemName: "cloud.fill")
                .font(.system(.largeTitle).weight(.regular))
                .imageScale(.large)
                .scaleEffect(1.8)
                .foregroundStyle(AppColors.primary.opacity(0.35))
            Image(systemName: "bookmark.fill")
                .font(.largeTitle)
                .foregroundStyle(AppColors.primary)
                .offset(y: 6)
        }
        .accessibilityHidden(true)
    }

    private var hintCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "bookmark")
                .font(.title3)
                .foregroundStyle(AppColors.primary)
                .accessibilityHidden(true)
            Text("Tap the bookmark on any suggested alternative to save it here.")
                .font(.subheadline)
                .foregroundStyle(AppColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview("Light") {
    NavigationStack { BackupsEmptyStateView(tripName: "Sydney Weekend") }
}

#Preview("Dark") {
    NavigationStack { BackupsEmptyStateView(tripName: "Sydney Weekend") }
        .preferredColorScheme(.dark)
}
