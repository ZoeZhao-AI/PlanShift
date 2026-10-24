//
//  LocationPermissionPromptView.swift
//  PlanShift
//
//  Created by Van Dao Le on 15/10/2026.
//

// Module: M2 – pre-prompt sheet shown by M2-02 before iOS asks for location (follows the M5-04 design).

import SwiftUI

/// Explains *why* location helps before iOS shows its own permission dialog (design ID M5-04).
/// "Allow location" is what triggers the system prompt (done by the caller); "Not now"
/// continues with the planned activity's location. Nothing is requested before the user taps.
///
/// Lives in M2 so the M2-02 flow does not depend on M5's placeholder screen; the M5 owner can swap
/// in their own view later. The closures keep the screen free of any location logic. The explanation
/// scrolls (so it never clips at large text sizes) while the two buttons stay pinned at the bottom.
struct LocationPermissionPromptView: View {
    var onAllow: () -> Void = {}
    var onNotNow: () -> Void = {}

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(AppColors.actionText)
                    .padding(.top, 24)
                    .accessibilityHidden(true)

                Text("Find alternatives near you")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                VStack(alignment: .leading, spacing: 12) {
                    bullet("mappin.and.ellipse", "Closer options", "Rank places by how near they are to you.")
                    bullet("ruler", "Better distance estimates", "Distances start from where you are.")
                    bullet("lock.shield", "Only while the app is open", "PlanShift never tracks you in the background.")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            .readableContentWidth()
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                ProminentButton("Allow location", action: onAllow)
                SecondaryButton("Not now", action: onNotNow)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
            .readableContentWidth()
            .background(.bar)
        }
        .background(AppColors.backgroundGradient)
        .tint(AppColors.actionText)
    }

    private func bullet(_ symbol: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol).foregroundStyle(AppColors.actionText).frame(width: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                Text(detail).font(.footnote).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Subviews (used only by this screen)

/// A full-width system secondary button (`.bordered`).
private struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title).frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }
}

// MARK: - Previews

#Preview("Location prompt · Light") { LocationPermissionPromptView() }

#Preview("Location prompt · Dark") { LocationPermissionPromptView().preferredColorScheme(.dark) }
