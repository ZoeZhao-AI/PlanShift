//
//  ReplaceConfirmationContent.swift
//  PlanShift
//
//  Created by Chang Chia ming on 2026/10/16.
//

import SwiftUI
import UIKit

struct ReplaceConfirmationContent: View {
    let original: ItineraryActivity
    let alternative: Place
    let viewModel: ReplaceViewModel
    let onCancel: () -> Void
    let onConfirmed: () -> Void

    private var buttonsDisabled: Bool {
        viewModel.isProcessing || viewModel.canUndo
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                header
                originalCard
                replacementArrow
                alternativeCard
                detailsCard
                backupNotice
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .background {
            AppColors.backgroundGradient
                .ignoresSafeArea()
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            actionButtons
        }
        .foregroundStyle(AppColors.textPrimary)
        .interactiveDismissDisabled(viewModel.isProcessing)
        .alert(
            "Unable to Update Plan",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        viewModel.clearError()
                    }
                }
            )
        ) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .accessibilityIdentifier("M3-01")
    }

    private var header: some View {
        ZStack {
            Text("Replace activity?")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            HStack {
                Button("Cancel", action: onCancel)
                    .foregroundStyle(AppColors.primary)
                    .frame(minWidth: 44, minHeight: 44)
                    .disabled(viewModel.isProcessing)

                Spacer()
            }
        }
        .padding(.top, 8)
    }

    private var originalCard: some View {
        HStack(spacing: 12) {
            Image(
                systemName: original.setting == .indoor
                    ? "building.2"
                    : "tree"
            )
            .font(.largeTitle)
            .foregroundStyle(AppColors.textSecondary)
            .frame(width: 72, height: 72)
            .background(AppColors.textSecondary.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                Text("BEFORE")
                    .font(.caption.weight(.semibold))

                Text(original.name)
                    .font(.headline)
                    .strikethrough()

                Text(
                    "\(timeRange(start: original.startTime, end: original.endTime)) · \(original.locationName) · \(original.setting.title)"
                )
                .font(.caption)
            }
            .foregroundStyle(AppColors.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private var replacementArrow: some View {
        Image(systemName: "arrow.down")
            .font(.title3.weight(.semibold))
            .foregroundStyle(AppColors.backgroundBottom)
            .frame(width: 48, height: 48)
            .background(AppColors.primary)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(AppColors.backgroundBottom, lineWidth: 3)
            }
            .accessibilityHidden(true)
    }

    private var alternativeCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            alternativeImage
                .overlay(alignment: .topLeading) {
                    Text("AFTER")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppColors.backgroundBottom)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(AppColors.primary)
                        .clipShape(Capsule())
                        .padding(12)
                }

            VStack(alignment: .leading, spacing: 10) {
                Text(alternative.name)
                    .font(.title3.weight(.semibold))

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) {
                        settingBadge
                        suburbLabel
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        settingBadge
                        suburbLabel
                    }
                }
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(AppColors.primary.opacity(0.5), lineWidth: 1)
        }
    }

    private var alternativeImage: some View {
        ZStack {
            AppColors.indoorBackground

            if !alternative.imageName.isEmpty,
               let image = UIImage(named: alternative.imageName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(
                    systemName: alternative.setting == .indoor
                        ? "building.columns"
                        : "tree"
                )
                .font(.largeTitle)
                .foregroundStyle(AppColors.primary)
            }
        }
        .frame(height: 130)
        .clipped()
        .accessibilityHidden(true)
    }

    private var settingBadge: some View {
        Label(
            alternative.setting.title,
            systemImage: alternative.setting == .indoor
                ? "house"
                : "leaf"
        )
        .font(.caption.weight(.medium))
        .foregroundStyle(
            alternative.setting == .indoor
                ? AppColors.indoorForeground
                : AppColors.outdoorForeground
        )
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            alternative.setting == .indoor
                ? AppColors.indoorBackground
                : AppColors.outdoorBackground
        )
        .clipShape(Capsule())
    }

    private var suburbLabel: some View {
        Text(alternative.suburb)
            .font(.caption)
            .foregroundStyle(AppColors.textSecondary)
    }

    private var detailsCard: some View {
        VStack(spacing: 0) {
            detailRow(
                symbol: "clock",
                title: "Time slot",
                value: proposedTimeRange
            )

            Divider()
                .overlay(AppColors.textSecondary.opacity(0.1))

            detailRow(
                symbol: "figure.walk",
                title: "Getting there",
                value: "Not available"
            )

            Divider()
                .overlay(AppColors.textSecondary.opacity(0.1))

            detailRow(
                symbol: "dollarsign.circle",
                title: "Cost",
                value: costText
            )
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private var backupNotice: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "bookmark")
                .foregroundStyle(AppColors.primary)
                .accessibilityHidden(true)

            Text(
                "\(original.name) will be kept in Backups, so you can switch back later."
            )
            .font(.caption)
            .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 6)
        .padding(.top, 4)
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button {
                Task {
                    let succeeded = await viewModel.confirm(
                        activity: original,
                        alternative: alternative
                    )

                    if succeeded {
                        onConfirmed()
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isProcessing {
                        ProgressView()
                            .tint(AppColors.backgroundBottom)
                    } else {
                        Image(systemName: "checkmark")
                    }

                    Text(
                        viewModel.isProcessing
                            ? "Replacing…"
                            : "Confirm replace"
                    )
                    .font(.headline)
                }
                .frame(maxWidth: .infinity, minHeight: 52)
                .foregroundStyle(AppColors.backgroundBottom)
                .background(AppColors.primary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(buttonsDisabled)
            .opacity(buttonsDisabled ? 0.65 : 1)

            Button(action: onCancel) {
                Text("Cancel")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .foregroundStyle(AppColors.textPrimary)
                    .background(cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(viewModel.isProcessing)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(AppColors.backgroundBottom)
    }

    private var cardBackground: Color {
        AppColors.backgroundTop
            .opacity(0.85)
    }

    private var proposedTimeRange: String {
        guard let endTime = viewModel.proposedEndTime(
            for: original,
            alternative: alternative
        ) else {
            return "Not available"
        }

        return timeRange(start: original.startTime, end: endTime)
    }

    private var costText: String {
        alternative.cost == 0
            ? "Free"
            : alternative.cost.formatted(.currency(code: "AUD"))
    }

    private func timeRange(start: Date, end: Date) -> String {
        let style = Date.FormatStyle()
            .hour(.twoDigits(amPM: .omitted))
            .minute(.twoDigits)

        return "\(start.formatted(style)) – \(end.formatted(style))"
    }

    private func detailRow(
        symbol: String,
        title: String,
        value: String
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(AppColors.primary)
                .frame(width: 20)
                .accessibilityHidden(true)

            Text(title)

            Spacer(minLength: 8)

            Text(value)
                .fontWeight(.semibold)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
        .padding(16)
        .frame(minHeight: 48)
    }
}

#Preview {
    ReplaceConfirmationContentPreview()
}

private struct ReplaceConfirmationContentPreview: View {
    @State private var viewModel: ReplaceViewModel
    @State private var showsConfirmation = true

    init() {
        let activities = MockActivityRepository(
            activities: [PreviewSamples.coastalWalk]
        )
        let backups = MockBackupRepository()

        _viewModel = State(
            initialValue: ReplaceViewModel(
                replaceActivity: ReplaceActivityUseCase(
                    activityRepository: activities,
                    backupRepository: backups
                ),
                undoReplace: UndoReplaceUseCase(
                    activityRepository: activities
                )
            )
        )
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(
                viewModel.replacementName
                    ?? PreviewSamples.coastalWalk.name
            )
            .font(.headline)
            .multilineTextAlignment(.center)

            Button("Show confirmation") {
                showsConfirmation = true
            }
            .disabled(viewModel.canUndo)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.backgroundGradient)
        .safeAreaInset(edge: .bottom) {
            UpdatedItineraryBannerContent(
                viewModel: viewModel,
                onUndone: {}
            )
        }
        .sheet(isPresented: $showsConfirmation) {
            ReplaceConfirmationContent(
                original: PreviewSamples.coastalWalk,
                alternative: PreviewSamples.australianMuseum,
                viewModel: viewModel,
                onCancel: {
                    showsConfirmation = false
                },
                onConfirmed: {
                    showsConfirmation = false
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }
}
