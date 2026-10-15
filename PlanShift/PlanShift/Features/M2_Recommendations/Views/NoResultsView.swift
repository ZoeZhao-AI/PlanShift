//
//  NoResultsView.swift
//  PlanShift
//
//  Created by Van Dao Le on 15/10/2026.
//

// Module: M2 – M2-04 No Results (a state of the results step, not a separate route).

import SwiftUI

/// Shown when no place passes the filters. Never invents matches; the single way out is
/// "Adjust filters", which returns to M2-02 with every selection intact.
///
/// The content is centred when it fits and scrolls when it does not (large text sizes), so nothing
/// is ever clipped.
struct NoResultsView: View {
    let activity: ItineraryActivity
    var disruption: Disruption?
    let filters: PreferenceFilters
    var showsLocationBanner = false
    let onAdjustFilters: () -> Void

    var body: some View {
        ViewThatFits(in: .vertical) {
            content(centered: true)
            ScrollView { content(centered: false) }
        }
    }

    private func content(centered: Bool) -> some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                if showsLocationBanner { LocationOffBanner() }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Instead of \(activity.name)")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.primary)
                    if let disruption {
                        Text("\(disruption.title) · \(M2Formatting.timeRange(of: activity))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                FilterSummaryChips(filters: filters, withinStyle: true)
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .readableContentWidth()

            if centered { Spacer(minLength: 16) } else { Color.clear.frame(height: 24) }

            VStack(spacing: 14) {
                NoResultsIllustration()

                Text("No activities match these filters")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text("\(M2Formatting.noResultsSentence(for: filters)) Try a wider distance or a different budget.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button(action: onAdjustFilters) {
                    Label("Adjust filters", systemImage: "arrow.left.arrow.right")
                }
                .prominentActionStyle()
                .padding(.top, 6)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, centered ? 0 : 24)

            if centered {
                Spacer(minLength: 16)
                Spacer(minLength: 16)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Subviews (used only by this screen)

/// The filters in effect as small grey capsules ("Outdoor", "Free", "Within 1 km", "Half day") on M2-04.
private struct FilterSummaryChips: View {
    let filters: PreferenceFilters
    var withinStyle = false

    var body: some View {
        let items = M2Formatting.summary(of: filters, withinStyle: withinStyle)
        FlowLayout(spacing: 8) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 5)
                    .background(Color(.tertiarySystemFill), in: Capsule())
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Filters: " + items.joined(separator: ", "))
    }
}

private struct NoResultsIllustration: View {
    private let lens = Color(light: 0x2F5FD0, dark: 0x60A5FA)

    var body: some View {
        ZStack {
            Ellipse()
                .fill(Color.black.opacity(0.07))
                .frame(width: 120, height: 12)
                .offset(y: 56)

            ZStack {
                Image(systemName: "cloud.fill").foregroundStyle(Color(light: 0xFFFFFF, dark: 0x1F3550))
                Image(systemName: "cloud").foregroundStyle(Color(light: 0xBFD6F5, dark: 0x3B5F8F))
            }
            .font(.system(size: 76, weight: .regular))
            .offset(x: -20, y: -14)

            ZStack {
                Capsule().fill(lens)
                    .frame(width: 34, height: 10)
                    .rotationEffect(.degrees(45))
                    .offset(x: 32, y: 34)
                Circle().fill(Color(light: 0xE4EEFF, dark: 0x1F3A63))
                    .frame(width: 58, height: 58)
                Circle().strokeBorder(lens, lineWidth: 7)
                    .frame(width: 58, height: 58)
                Image(systemName: "xmark")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(AppColors.coral)
            }
            .offset(x: 22, y: 6)

            Circle().fill(Color(light: 0xFBBF24, dark: 0xFBBF24))
                .frame(width: 8, height: 8)
                .offset(x: 62, y: -30)
        }
        .frame(width: 170, height: 130)
        .accessibilityHidden(true)
    }
}

// MARK: - Previews (M2-04)

private let noResultsFilters = PreferenceFilters(budget: .free, maxDistance: .oneKm, duration: .halfDay, setting: .outdoor)

#Preview("M2-04 · Light") {
    NoResultsView(activity: PreviewSamples.tarongaZoo, disruption: .rainyWeather, filters: noResultsFilters) {}
        .background(AppColors.backgroundGradient)
}

#Preview("M2-04 · Dark") {
    NoResultsView(activity: PreviewSamples.tarongaZoo, disruption: .rainyWeather, filters: noResultsFilters) {}
        .background(AppColors.backgroundGradient)
        .preferredColorScheme(.dark)
}

#Preview("M2-04 · With location banner") {
    NoResultsView(activity: PreviewSamples.tarongaZoo, disruption: .transportDelay, filters: noResultsFilters, showsLocationBanner: true) {}
        .background(AppColors.backgroundGradient)
}
