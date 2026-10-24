//
//  RankedAlternativesView.swift
//  PlanShift
//
//  Created by Van Dao Le on 15/10/2026.
//

// Module: M2 – M2-03 Ranked Alternatives (also hosts the M2-04 empty state and the location banner). UI only.

import SwiftUI
import UIKit

/// What the results screen is showing. A plain value the screen displays; it does not decide it.
enum AlternativesScreenState: Equatable {
    case loading
    case results([RankedAlternative])
    /// M2-04 – nothing matched the filters.
    case empty
    case failed(String)
}

/// M2-03. The top three ranked places with reason tags, plus up to five more behind "See more options".
///
/// UI only: the list, the saved bookmarks, the banner and the toast all arrive as parameters, and
/// bookmark / retry / toast taps leave through closures. Replace just pushes M3's confirmation screen.
/// Chrome is the system navigation bar: the back button returns to the filters; "Cancel" leaves the flow.
struct RankedAlternativesView: View {
    let activity: ItineraryActivity
    let filters: PreferenceFilters
    var disruption: Disruption?
    var state: AlternativesScreenState
    /// Place ids that show a filled bookmark.
    var savedIds: Set<UUID> = []
    /// Place ids whose bookmark is busy (disabled while saving).
    var busyIds: Set<UUID> = []
    /// Shows the "Location is off" banner above the results.
    var showsLocationBanner = false
    var originFootnote = "Distances are approximate, measured in a straight line from your planned activity. Walking times are estimates."
    var toast: ToastMessage?
    var onBookmark: (RankedAlternative) -> Void = { _ in }
    var onTryAgain: () -> Void = {}
    /// Tap on a toast's action ("View").
    var onToastAction: () -> Void = {}

    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Set when Replace is tapped; pushes M3's confirmation screen.
    @State private var replacementTarget: Place?
    /// "See more options" was tapped. Collapses again whenever a new search starts.
    @State private var showsMoreResults = false

    /// How many results are shown before "See more options".
    private static let initiallyShown = 3

    var body: some View {
        content
            .background(AppColors.backgroundGradient)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // The system back button returns to the filters; "Cancel" leaves the whole flow.
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { router.dismissSheet() }
                        .accessibilityHint("Closes without changing your itinerary")
                }
            }
            .tint(AppColors.actionText)
            .safeAreaInset(edge: .bottom) {
                if let toast {
                    ToastView(
                        message: toast.text,
                        style: toast.kind == .success ? .success : (toast.kind == .warning ? .warning : .error),
                        actionTitle: toast.actionTitle,
                        action: onToastAction
                    )
                    .padding(.bottom, 8)
                    // Reduce Motion: fade instead of sliding.
                    .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: toast)
            .sensoryFeedback(trigger: toast) { _, new in
                guard let new else { return nil }
                switch new.kind {
                case .success: return .success
                case .warning: return .warning
                case .error: return .error
                }
            }
            .onChange(of: state) { _, newState in
                showsMoreResults = false
                switch newState {
                case .results(let list):
                    if let best = list.first {
                        let visible = min(list.count, Self.initiallyShown)
                        UIAccessibility.post(notification: .announcement, argument: "\(visible) alternatives found. Best match: \(best.place.name).")
                    }
                case .empty:
                    UIAccessibility.post(notification: .announcement, argument: "No activities match these filters.")
                case .failed(let message):
                    UIAccessibility.post(notification: .announcement, argument: message)
                case .loading:
                    break
                }
            }
            .navigationDestination(item: $replacementTarget) { place in
                ReplaceConfirmationView(original: activity, alternative: place)
            }
    }

    private var title: String {
        switch state {
        case .results(let list): list.count >= Self.initiallyShown ? "Top 3 alternatives" : "Top alternatives"
        default: "Alternatives"
        }
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .loading:
            VStack(spacing: 12) {
                ProgressView()
                Text("Finding alternatives…").font(.subheadline).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityElement(children: .combine)
        case .results(let alternatives):
            resultsList(alternatives)
        case .empty:
            NoResultsView(activity: activity, disruption: disruption, filters: filters, showsLocationBanner: showsLocationBanner) { dismiss() }
        case .failed(let message):
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill").font(.largeTitle).foregroundStyle(AppColors.warningText)
                Text("Something went wrong").font(.headline).foregroundStyle(.primary)
                Text(message).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                ProminentButton("Try again", action: onTryAgain)
                Button("Adjust filters") { dismiss() }.frame(minHeight: 44)
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func resultsList(_ alternatives: [RankedAlternative]) -> some View {
        let hiddenCount = max(0, alternatives.count - Self.initiallyShown)
        let shown = showsMoreResults ? alternatives : Array(alternatives.prefix(Self.initiallyShown))
        return ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if showsLocationBanner { LocationOffBanner() }
                header
                ForEach(shown) { alternative in
                    AlternativeCardView(
                        alternative: alternative,
                        isSaved: savedIds.contains(alternative.place.id),
                        isBusy: busyIds.contains(alternative.place.id),
                        onBookmark: { onBookmark(alternative) },
                        onReplace: { replacementTarget = alternative.place }
                    )
                }
                if hiddenCount > 0 && !showsMoreResults {
                    seeMoreButton(hiddenCount: hiddenCount)
                }
                Text(originFootnote)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 2)
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 16)
            .readableContentWidth()
        }
    }

    /// Reveals results #4 onwards in place, in the same compact style as #2 and #3.
    private func seeMoreButton(hiddenCount: Int) -> some View {
        Button {
            showsMoreResults = true
            UIAccessibility.post(notification: .announcement, argument: "\(Self.initiallyShown + hiddenCount) alternatives shown.")
        } label: {
            Label("See more options", systemImage: "chevron.down")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.actionText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("See \(hiddenCount) more \(hiddenCount == 1 ? "option" : "options")")
    }

    /// "Instead of Taronga Zoo" + one-line filter summary, with "Adjust filters" on the right.
    private var header: some View {
        // At accessibility sizes "Adjust filters" goes under the title instead of squeezing it.
        let layout = dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4)) : AnyLayout(HStackLayout(alignment: .center, spacing: 12))
        return layout {
            VStack(alignment: .leading, spacing: 3) {
                Text("Instead of \(activity.name)")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.primary)
                Text(M2Formatting.summary(of: filters).joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: 4) }
            Button {
                dismiss()
            } label: {
                Label("Adjust filters", systemImage: "arrow.left.arrow.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.actionText)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Goes back to the filters")
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Toast data (internal: also used by the logic layer when it is wired in)

/// A short message shown at the bottom of M2-03 (success, or the M4-04 duplicate warning).
struct ToastMessage: Identifiable, Equatable {
    enum Kind { case success, warning, error }

    let id = UUID()
    let kind: Kind
    let text: String
    /// e.g. "View" → opens the Backups tab.
    let actionTitle: String?
}

// MARK: - Subviews (used only by this screen)

private struct AlternativeCardView: View {
    let alternative: RankedAlternative
    let isSaved: Bool
    let isBusy: Bool
    let onBookmark: () -> Void
    let onReplace: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var heroHeight: CGFloat = 100
    @ScaledMetric(relativeTo: .body) private var thumbnail: CGFloat = 56

    private var place: Place { alternative.place }
    private var isFeatured: Bool { alternative.rank == 1 }

    private var distanceText: String? { alternative.distanceMeters.map(M2Formatting.distance(meters:)) }
    private var durationText: String { M2Formatting.duration(minutes: place.durationMinutes) }
    private var costText: String { M2Formatting.cost(place.cost) }

    var body: some View {
        Group {
            if isFeatured { featured } else { compact }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(isFeatured ? "Best match: \(place.name)" : "Number \(alternative.rank): \(place.name)")
    }

    // MARK: Featured (#1)

    private var featured: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                PlaceArtworkView(name: place.name, setting: place.setting, imageName: place.imageName)
                    .frame(maxWidth: .infinity)
                    .frame(height: heroHeight)
                    .clipped()
                HStack(alignment: .top) {
                    Label("Best match", systemImage: "star.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppColors.ctaFill, in: Capsule())
                    Spacer()
                    bookmarkButton
                        .background(.regularMaterial, in: Circle())
                }
                .padding(10)
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text(place.name)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)
                    Spacer(minLength: 8)
                    Text("#1")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(AppColors.ctaFill, in: Capsule())
                        .accessibilityLabel("Rank 1")
                }
                stats
                tags
                ProminentButton("Replace", action: onReplace)
                    .accessibilityLabel("Replace with \(place.name)")
            }
            .padding(16)
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(AppColors.actionText.opacity(0.35), lineWidth: 1.5))
    }

    private var stats: some View {
        let layout = dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 8)) : AnyLayout(HStackLayout(spacing: 8))
        return layout {
            stat("Distance", distanceText ?? "—")
            stat("Duration", durationText)
            stat("Cost", costText)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Distance \(distanceText.map { "about " + $0 } ?? "not available"). Duration \(durationText). Cost \(costText).")
    }

    private func stat(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.callout.weight(.semibold)).foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: Compact (#2, #3)

    private var compact: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                PlaceArtworkView(name: place.name, setting: place.setting, imageName: place.imageName)
                    .frame(width: thumbnail, height: thumbnail)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("#\(alternative.rank)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.tertiarySystemFill), in: Capsule())
                            .accessibilityLabel("Rank \(alternative.rank)")
                        Text(place.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                    }
                    Text([distanceText, durationText, costText].compactMap { $0 }.joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                bookmarkButton
            }

            let layout = dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10)) : AnyLayout(HStackLayout(alignment: .center, spacing: 8))
            layout {
                tags
                if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: 0) }
                Button("Replace", action: onReplace)
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.ctaFill)
                    .controlSize(.large)
                    .accessibilityLabel("Replace with \(place.name)")
            }
        }
        .padding(16)
        .cardSurface(cornerRadius: 20)
    }

    // MARK: Shared

    /// Bookmark toggle: outline when not saved, filled when saved (shape, not just colour, shows the state).
    private var bookmarkButton: some View {
        Button(action: onBookmark) {
            Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                .font(.body.weight(.semibold))
                .foregroundStyle(AppColors.actionText)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isBusy)
        .accessibilityLabel("Backup \(place.name)")
        .accessibilityValue(isSaved ? "Saved" : "Not saved")
        .accessibilityHint("Saves this place to your backups")
    }

    /// The design shows up to three tags on the best match and two on the compact cards.
    private var tags: some View {
        let shown = Array(alternative.reasons.prefix(isFeatured ? 3 : 2))
        return FlowLayout(spacing: 6) {
            ForEach(shown) { ReasonTagChip(tag: $0) }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Why: " + shown.map(\.accessibilityText).joined(separator: ", "))
    }
}

/// A reason tag such as "Indoors" or "~22 min walk".
private struct ReasonTagChip: View {
    let tag: ReasonTag

    var body: some View {
        Label(tag.displayText, systemImage: tag.symbolName)
            .labelStyle(TagLabelStyle())
            .font(.caption2.weight(.semibold))
            .foregroundStyle(AppColors.actionText)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(AppColors.actionText.opacity(0.14), in: Capsule())
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel(tag.accessibilityText)
    }
}

private struct TagLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 5) {
            configuration.icon.imageScale(.small)
            configuration.title
        }
    }
}

/// A short confirmation with an optional action, e.g. "Saved to backups  View" (M2-03) or the M4-04
/// duplicate warning. Uses a system material and semantic colours; callers decide when to show and hide it.
private struct ToastView: View {
    enum Style { case success, warning, error }

    let message: String
    var style: Style = .success
    var actionTitle: String?
    var action: (() -> Void)?

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var symbol: String {
        switch style {
        case .success: "checkmark.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .error: "xmark.octagon.fill"
        }
    }

    private var symbolColor: Color {
        switch style {
        case .success: AppColors.actionText
        case .warning: .orange
        case .error: AppColors.warningText
        }
    }

    var body: some View {
        // At accessibility sizes the action sits under the message so the message keeps the full width.
        let layout = dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4)) : AnyLayout(HStackLayout(spacing: 12))
        layout {
            Image(systemName: symbol)
                .foregroundStyle(symbolColor)
                .accessibilityHidden(true)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.actionText)
                    .frame(minWidth: 44, minHeight: 44)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .frame(minHeight: 52)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color(.separator), lineWidth: 0.5))
        .padding(.horizontal, 16)
        .accessibilityElement(children: .contain)
        .onAppear { UIAccessibility.post(notification: .announcement, argument: message) }
    }
}

// MARK: - Previews (M2-03, M2-04, loading, error, location banner, toasts)

private func resultsPreview(
    state: AlternativesScreenState = .results(M2SampleData.alternatives),
    filters: PreferenceFilters = M2SampleData.rainyFilters,
    savedIds: Set<UUID> = [],
    showsLocationBanner: Bool = false,
    toast: ToastMessage? = nil
) -> some View {
    NavigationStack {
        RankedAlternativesView(
            activity: M2SampleData.activity, filters: filters, disruption: .rainyWeather, state: state,
            savedIds: savedIds, showsLocationBanner: showsLocationBanner, toast: toast
        )
    }
    .environment(AppRouter())
}

private let sampleSavedId = M2SampleData.alternatives[1].place.id

#Preview("M2-03 · Light") { resultsPreview(savedIds: [sampleSavedId]) }

#Preview("M2-03 · Dark") { resultsPreview(savedIds: [sampleSavedId]).preferredColorScheme(.dark) }

#Preview("M2-03 · Saved to backups toast") {
    resultsPreview(
        savedIds: [M2SampleData.alternatives[0].place.id],
        toast: ToastMessage(kind: .success, text: "Saved to backups", actionTitle: "View")
    )
}

#Preview("M4-04 · Already in backups toast") {
    resultsPreview(
        savedIds: [sampleSavedId],
        toast: ToastMessage(kind: .warning, text: "This activity is already in your backups", actionTitle: "View")
    )
}

#Preview("Location off banner") { resultsPreview(showsLocationBanner: true) }

#Preview("M2-04 · No results") { resultsPreview(state: .empty, filters: M2SampleData.noMatchFilters) }

#Preview("Loading") { resultsPreview(state: .loading) }

#Preview("Error") { resultsPreview(state: .failed("The built-in list of places could not be found.")) }

#Preview("M2-03 · Unknown distance (no location at all)") {
    resultsPreview(state: .results([
        RankedAlternative(rank: 1, place: PreviewSamples.australianMuseum, distanceMeters: nil, walkingMinutes: nil,
                          reasons: [.indoors, .free], score: 0.6)
    ]))
}
