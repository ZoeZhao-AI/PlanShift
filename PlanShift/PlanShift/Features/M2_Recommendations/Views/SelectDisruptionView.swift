//
//  SelectDisruptionView.swift
//  PlanShift
//
//  Created by Van Dao Le on 15/10/2026.
//

// Module: M2 – M2-01 Select Disruption (first screen of the disruption sheet). UI only.

import SwiftUI

/// M2-01 "Plan changed?". Four cards to pick what went wrong; picking one opens M2-02.
///
/// UI only: no view model, use case or repository. It keeps just the state the screen itself needs to
/// *look* right (which card is selected, which screen is pushed) and uses fixed sample data for the
/// following screens. The real logic is wired in later.
///
/// Chrome is the system navigation bar: inline title and a standard "Cancel".
struct SelectDisruptionView: View {
    let activity: ItineraryActivity
    /// "Day 1"; when nil the activity's date is shown instead.
    var dayLabel: String?

    @Environment(AppRouter.self) private var router
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var disruption: Disruption?
    @State private var filters = PreferenceFilters()
    @State private var showsFilters = false
    @State private var showsResults = false

    init(activity: ItineraryActivity, dayLabel: String? = nil, selected: Disruption? = nil) {
        self.activity = activity
        self.dayLabel = dayLabel
        _disruption = State(initialValue: selected)
    }

    private var resolvedDayLabel: String { dayLabel ?? M2Formatting.dayLabel(for: activity, tripStart: nil) }
    private var restOfDay: String { resolvedDayLabel.hasPrefix("Day") ? resolvedDayLabel : "the day" }

    private var columns: [GridItem] {
        dynamicTypeSize.isAccessibilitySize
            ? [GridItem(.flexible())]
            : [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ActivitySummaryCard(activity: activity, dayLabel: resolvedDayLabel)

                VStack(alignment: .leading, spacing: 4) {
                    Text("What went wrong?")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                        .accessibilityAddTraits(.isHeader)
                    Text("Pick one. We'll find the best swap nearby.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(Disruption.allCases) { item in
                        DisruptionCard(disruption: item, isSelected: disruption == item) {
                            disruption = item
                            filters = Self.placeholderFilters(for: item)
                            showsFilters = true
                        }
                    }
                }

                Text("Only this activity changes. The rest of \(restOfDay) stays as planned.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
            .readableContentWidth()
        }
        .background(AppColors.backgroundGradient)
        .navigationTitle("Plan changed?")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { router.dismissSheet() }
                    .accessibilityHint("Closes without changing your itinerary")
            }
        }
        .tint(AppColors.actionText)
        .sensoryFeedback(.selection, trigger: disruption)
        .navigationDestination(isPresented: $showsFilters) {
            if let disruption {
                PreferenceFiltersView(
                    activity: activity,
                    disruption: disruption,
                    filters: $filters,
                    onReset: { filters = Self.placeholderFilters(for: disruption) },
                    onShowAlternatives: { showsResults = true }
                )
                .navigationDestination(isPresented: $showsResults) {
                    RankedAlternativesView(
                        activity: activity,
                        filters: filters,
                        disruption: disruption,
                        state: .results(M2SampleData.alternatives)
                    )
                }
            }
        }
    }

    /// PLACEHOLDER so M2-02 opens with sensible chips selected, as in the design. The real starting
    /// filters come from the "apply disruption defaults" use case when the logic is added.
    private static func placeholderFilters(for disruption: Disruption) -> PreferenceFilters {
        switch disruption {
        case .rainyWeather: M2SampleData.rainyFilters
        case .attractionClosed: PreferenceFilters()
        case .transportDelay: PreferenceFilters(maxDistance: .oneKm)
        case .runningOutOfTime: PreferenceFilters(duration: .underOneHour)
        }
    }
}

// MARK: - Subviews (used only by this screen)

private struct DisruptionCard: View {
    let disruption: Disruption
    let isSelected: Bool
    let action: () -> Void

    @ScaledMetric(relativeTo: .body) private var iconBox: CGFloat = 52

    /// The design breaks "Running out of / time" after "of"; iOS would otherwise balance it as "Running out / of time".
    private var cardTitle: String {
        disruption == .runningOutOfTime ? "Running out of\ntime" : disruption.title
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    DisruptionIcon(disruption: disruption)
                        .font(.title2)
                        .frame(width: iconBox, height: iconBox)
                        .background(Color(.systemBackground).opacity(0.85), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    Spacer(minLength: 0)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 26, height: 26)
                            .background(AppColors.ctaFill, in: Circle())
                    }
                }
                Spacer(minLength: 16)
                Text(cardTitle)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                Text(disruption.subtitle)
                    .font(.caption)
                    .foregroundStyle(AppColors.secondaryOnTint)
                    .multilineTextAlignment(.leading)
                    .padding(.top, 2)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
            .background(disruption.tint.opacity(0.16), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(isSelected ? AppColors.ctaFill : .clear, lineWidth: 2)
            )
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(disruption.title). \(disruption.subtitle)")
        .accessibilityHint("Opens preference filters")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

/// The affected activity at the top of M2-01.
private struct ActivitySummaryCard: View {
    let activity: ItineraryActivity
    /// "Day 1" or a date.
    let dayLabel: String

    @ScaledMetric(relativeTo: .body) private var thumbnail: CGFloat = 60
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        // At accessibility sizes the text needs the full card width: put the picture above it.
        let layout = dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12)) : AnyLayout(HStackLayout(spacing: 12))
        layout {
            PlaceArtworkView(name: activity.name, setting: activity.setting, imageName: M2Formatting.imageSlug(for: activity.name))
                .frame(width: min(thumbnail, 96), height: min(thumbnail, 96))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text("Affected activity")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AppColors.affectedForeground)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppColors.affectedBackground, in: Capsule())
                    .fixedSize(horizontal: false, vertical: true)
                Text(activity.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("\(dayLabel) · \(M2Formatting.timeRange(of: activity)) · \(activity.setting.title)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: 0) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .cardSurface(cornerRadius: 20)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Affected activity: \(activity.name), \(dayLabel), \(M2Formatting.timeRange(of: activity)), \(activity.setting.title)")
    }
}

// MARK: - Previews (M2-01)

#Preview("M2-01 · Light") {
    NavigationStack { SelectDisruptionView(activity: M2SampleData.activity, dayLabel: "Day 1") }
        .environment(AppRouter())
}

#Preview("M2-01 · Dark") {
    NavigationStack { SelectDisruptionView(activity: M2SampleData.activity, dayLabel: "Day 1") }
        .environment(AppRouter())
        .preferredColorScheme(.dark)
}

#Preview("M2-01 · Rainy selected") {
    NavigationStack { SelectDisruptionView(activity: M2SampleData.activity, dayLabel: "Day 1", selected: .rainyWeather) }
        .environment(AppRouter())
}
