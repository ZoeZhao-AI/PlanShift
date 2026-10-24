// Module: M4 – M4-02 Use a Backup: choose which activity the backup replaces, then open M3-01.

import SwiftUI

/// M4-02. Talks only to `UseBackupViewModel`; no repositories or Core Data here.
///
/// MOCK WIRING: until M1 stores trips and activities, the screen uses `PreviewSamples.trip` and the
/// same sample activity that M3's mock knows (see `UseBackupViewModel.mocked(backup:)`).
struct UseBackupView: View {
    let trip: Trip

    @Environment(AppRouter.self) private var router
    @State private var viewModel: UseBackupViewModel

    /// With no view model, the screen uses the mock wiring below.
    init(backup: BackupOption, viewModel: UseBackupViewModel? = nil, trip: Trip = PreviewSamples.trip) {
        _viewModel = State(initialValue: viewModel ?? .mocked(backup: backup))
        self.trip = trip
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                BackupRowCard(row: viewModel.backupRow, badge: "Backup", showsChevron: false)

                Text("Replace which activity?")
                    .font(.headline)
                    .foregroundStyle(AppColors.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                DaySelector(
                    days: viewModel.days,
                    selectedDay: viewModel.selectedDay,
                    onSelect: { day in Task { await viewModel.selectDay(day) } }
                )

                activities
            }
            .padding()
        }
        .background(AppColors.backgroundGradient)
        .navigationTitle("Use backup")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { router.dismissSheet() }
            }
        }
        .safeAreaInset(edge: .bottom) {
            continueButton
        }
        .alert("Something went wrong", isPresented: isShowingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .task {
            await viewModel.load(trip: trip)
        }
    }

    @ViewBuilder
    private var activities: some View {
        if viewModel.isLoading {
            ProgressView("Loading activities…")
                .frame(maxWidth: .infinity)
                .padding()
        } else if viewModel.isDayEmpty {
            NoticeCard(systemImage: "calendar", text: viewModel.emptyDayMessage)
        } else {
            VStack(spacing: 10) {
                ForEach(viewModel.activityRows) { row in
                    ActivityChoiceCard(
                        row: row,
                        isSelected: row.id == viewModel.selectedActivityId,
                        onSelect: { viewModel.selectActivity(id: row.id) }
                    )
                }
            }
        }
    }

    private var continueButton: some View {
        Button {
            guard let original = viewModel.selectedActivity, let place = viewModel.place else { return }
            router.present(
                .replaceConfirmation(original: original, alternative: place, restoring: viewModel.originalPlan)
            )
        } label: {
            Text("Continue")
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.borderedProminent)
        .tint(AppColors.primary)
        .disabled(!viewModel.canContinue)
        .accessibilityHint(viewModel.canContinue ? "Opens the replace confirmation" : "Choose an activity first")
        .padding()
        .background(.bar)
    }

    /// Shows the alert while there is an error; dismissing it clears the error.
    private var isShowingError: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { isShowing in
                if !isShowing { viewModel.clearError() }
            }
        )
    }
}

/// "Day 1 / Fri 13" buttons. Scrolls sideways if the days do not fit.
private struct DaySelector: View {
    let days: [UseBackupDay]
    let selectedDay: Date?
    let onSelect: (Date) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(days) { day in
                    let isSelected = day.date == selectedDay
                    Button {
                        onSelect(day.date)
                    } label: {
                        VStack(spacing: 2) {
                            Text(day.title)
                                .font(.subheadline.weight(.semibold))
                            Text(day.shortDate)
                                .font(.caption)
                        }
                        .foregroundStyle(isSelected ? Color.white : AppColors.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .frame(minWidth: 44, minHeight: 44)
                        .background(
                            isSelected ? AnyShapeStyle(AppColors.primary) : AnyShapeStyle(.regularMaterial),
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
    }
}

/// One activity with a radio circle. Only one can be selected.
private struct ActivityChoiceCard: View {
    let row: ActivityChoiceRow
    let isSelected: Bool
    let onSelect: () -> Void

    @ScaledMetric(relativeTo: .body) private var scaledThumbnailSize: CGFloat = 48
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                if !dynamicTypeSize.isAccessibilitySize {
                    thumbnail
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(row.title)
                        .font(.headline)
                        .foregroundStyle(AppColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(row.timeRange)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                    Text(row.setting.title)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(row.setting == .indoor ? AppColors.indoorForeground : AppColors.outdoorForeground)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            row.setting == .indoor ? AppColors.indoorBackground : AppColors.outdoorBackground,
                            in: Capsule()
                        )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? AppColors.primary : AppColors.textSecondary)
            }
            .padding(12)
            .frame(minHeight: 44)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isSelected ? AppColors.primary : Color.clear, lineWidth: 2)
            }
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        // VoiceOver: "Coastal Walk, 09:00 – 12:00, Outdoor, Selected".
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(row.title), \(row.timeRange), \(row.setting.title)")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    /// Activities have no photos, so show the setting as an icon.
    private var thumbnail: some View {
        let size = min(scaledThumbnailSize, 72)
        return RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(row.setting == .indoor ? AppColors.indoorBackground : AppColors.outdoorBackground)
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: row.setting == .indoor ? "building.columns" : "sun.max")
                    .font(.title3)
                    .foregroundStyle(row.setting == .indoor ? AppColors.indoorForeground : AppColors.outdoorForeground)
            }
            .accessibilityHidden(true)
    }
}

/// A small card with an icon and a short message.
private struct NoticeCard: View {
    let systemImage: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(AppColors.textSecondary)
                .accessibilityHidden(true)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(AppColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Mock wiring

extension UseBackupViewModel {
    /// Only the activity M3's mock repository knows (see RootView), so Continue → Replace works end to end.
    private static let mockActivities = MockActivityRepository(activities: [PreviewSamples.coastalWalk])

    /// A view model on the sample activities. Swap in the real repository when it exists.
    static func mocked(backup: BackupOption) -> UseBackupViewModel {
        mocked(backup: backup, repository: mockActivities)
    }

    static func mocked(backup: BackupOption, repository: any ActivityRepository) -> UseBackupViewModel {
        UseBackupViewModel(
            backup: backup,
            fetchDayActivities: FetchDayActivitiesUseCase(repository: repository)
        )
    }
}

// MARK: - Previews

private let previewBackup = BackupOption(
    tripId: PreviewSamples.trip.id,
    content: .place(PreviewSamples.australianMuseum),
    dayDate: PreviewSamples.date(day: 14)
)

#Preview("Light") {
    NavigationStack {
        UseBackupView(
            backup: previewBackup,
            viewModel: .mocked(backup: previewBackup, repository: MockActivityRepository(activities: PreviewSamples.activities))
        )
    }
    .environment(AppRouter())
}

#Preview("Dark") {
    NavigationStack {
        UseBackupView(
            backup: previewBackup,
            viewModel: .mocked(backup: previewBackup, repository: MockActivityRepository(activities: PreviewSamples.activities))
        )
    }
    .environment(AppRouter())
    .preferredColorScheme(.dark)
}

#Preview("Original plan") {
    let backup = BackupOption(
        tripId: PreviewSamples.trip.id,
        content: .activity(PreviewSamples.tarongaZoo),
        dayDate: PreviewSamples.date(day: 14)
    )
    NavigationStack { UseBackupView(backup: backup) }
        .environment(AppRouter())
}
