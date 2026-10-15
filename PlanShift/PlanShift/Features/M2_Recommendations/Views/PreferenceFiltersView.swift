//
//  PreferenceFiltersView.swift
//  PlanShift
//
//  Created by Van Dao Le on 15/10/2026.
//

// Module: M2 – M2-02 Quick Preference Filters. UI only.

import SwiftUI

/// M2-02. Four filter groups, Reset, and "Show alternatives".
///
/// UI only: everything it shows comes in through parameters and everything the user does goes out
/// through closures, so the logic can be attached later without touching this file.
///
/// Chrome is the system navigation bar (automatic back button, trailing "Reset"); each filter is a system
/// segmented control (a menu at accessibility text sizes); the primary action sits in a system bar below.
struct PreferenceFiltersView: View {
    let activity: ItineraryActivity
    let disruption: Disruption
    @Binding var filters: PreferenceFilters
    /// "Near your location" / "Near your planned activity · Bondi Beach".
    var originDescription = "Near your location"
    var isLoading = false
    /// Shows the location pre-prompt sheet (used by the preview; the real trigger comes with the logic).
    var showsLocationPrompt = false
    var onReset: () -> Void = {}
    var onShowAlternatives: () -> Void = {}
    var onAllowLocation: () -> Void = {}
    var onNotNow: () -> Void = {}

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var note: String {
        switch disruption {
        case .rainyWeather: "Set to Indoor because of rain. Change it anytime."
        case .attractionClosed: "We'll look for something similar to your original plan."
        case .transportDelay: "Distance set to 1 km so you can stay close by."
        case .runningOutOfTime: "Duration set to under 1 hour for a quicker visit."
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                contextRow

                VStack(alignment: .leading, spacing: 20) {
                    FilterOptionPicker(title: "Budget", symbol: "dollarsign.circle", options: BudgetOption.allCases,
                                       selection: $filters.budget) { $0.title }
                    FilterOptionPicker(title: "Max distance", symbol: "mappin", options: DistanceOption.allCases,
                                       selection: $filters.maxDistance) { $0.title }
                    FilterOptionPicker(title: "Duration", symbol: "clock", options: DurationOption.allCases,
                                       selection: $filters.duration) { $0.title }
                    FilterOptionPicker(title: "Indoor / outdoor", symbol: "umbrella", options: SettingPreference.allCases,
                                       selection: $filters.setting) { $0.title }
                    Text(note).font(.footnote).foregroundStyle(.secondary)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardSurface(cornerRadius: 24)

                // At accessibility sizes the bottom bar keeps only the button; this note moves into the scroll.
                if dynamicTypeSize.isAccessibilitySize { originLabel }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .readableContentWidth()
        }
        .background(AppColors.backgroundGradient)
        .navigationTitle("Preferences")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Reset", action: onReset)
                    .accessibilityLabel("Reset filters")
                    .accessibilityHint("Restores the suggested filters for this disruption")
            }
        }
        .tint(AppColors.actionText)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 10) {
                if !dynamicTypeSize.isAccessibilitySize { originLabel }
                ProminentButton("Show alternatives", action: onShowAlternatives)
                    .disabled(isLoading)
                    .accessibilityHint("Finds up to three replacement places")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .readableContentWidth()
            .background(.bar)
        }
        .sheet(isPresented: .constant(showsLocationPrompt)) {
            LocationPermissionPromptView(onAllow: onAllowLocation, onNotNow: onNotNow)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    /// "➤ Near your location" – where distances are measured from.
    private var originLabel: some View {
        Label(originDescription, systemImage: "location.fill")
            .labelStyle(.titleAndIcon)
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    /// "☁ Rainy weather   Replacing Taronga Zoo · 12:30 – 15:30"
    private var contextRow: some View {
        let layout = dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 6)) : AnyLayout(HStackLayout(spacing: 10))
        return layout {
            Label {
                Text(disruption.title).foregroundStyle(disruption.textTint)
            } icon: {
                DisruptionIcon(disruption: disruption)
            }
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(disruption.tint.opacity(0.14), in: Capsule())

            Text("Replacing \(activity.name) · \(M2Formatting.timeRange(of: activity))")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 1)
                .minimumScaleFactor(0.85)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Subviews (used only by this screen)

/// HIG: a small set of mutually exclusive, closely related options is a segmented control. At accessibility
/// text sizes the segments would truncate, so the system menu picker is used instead.
private struct FilterOptionPicker<Option: Hashable & Identifiable>: View {
    let title: String
    let symbol: String
    let options: [Option]
    @Binding var selection: Option
    let label: (Option) -> String

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text(title)
            } icon: {
                Image(systemName: symbol).foregroundStyle(AppColors.actionText)
            }
            .font(.subheadline.weight(.semibold))
            .accessibilityAddTraits(.isHeader)

            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    picker.pickerStyle(.menu).frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    picker.pickerStyle(.segmented)
                }
            }
            .labelsHidden()
            .controlSize(.large)
        }
        .accessibilityElement(children: .contain)
    }

    private var picker: some View {
        Picker(title, selection: $selection) {
            ForEach(options) { option in
                Text(label(option)).tag(option)
            }
        }
    }
}

// MARK: - Previews (M2-02)

/// Gives a preview a mutable filter binding.
private struct FiltersPreviewHost: View {
    let disruption: Disruption
    @State var filters: PreferenceFilters
    var originDescription = "Near your location"
    var showsLocationPrompt = false

    var body: some View {
        NavigationStack {
            PreferenceFiltersView(
                activity: M2SampleData.activity, disruption: disruption, filters: $filters,
                originDescription: originDescription, showsLocationPrompt: showsLocationPrompt
            )
        }
        .environment(AppRouter())
    }
}

#Preview("M2-02 · Light (rainy)") {
    FiltersPreviewHost(disruption: .rainyWeather, filters: M2SampleData.rainyFilters)
}

#Preview("M2-02 · Dark (transport delay)") {
    FiltersPreviewHost(disruption: .transportDelay, filters: PreferenceFilters(maxDistance: .oneKm))
        .preferredColorScheme(.dark)
}

#Preview("M2-02 · Running out of time") {
    FiltersPreviewHost(disruption: .runningOutOfTime, filters: PreferenceFilters(duration: .underOneHour))
}

#Preview("M2-02 · Planned-activity origin") {
    FiltersPreviewHost(disruption: .rainyWeather, filters: M2SampleData.rainyFilters,
                       originDescription: "Near your planned activity · Mosman")
}

#Preview("M2-02 · Location pre-prompt") {
    FiltersPreviewHost(disruption: .rainyWeather, filters: M2SampleData.rainyFilters, showsLocationPrompt: true)
}
