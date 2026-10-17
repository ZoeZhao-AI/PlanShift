// Module: M4 – M4-01 Backups List: the trip's backups by day, with swipe and Edit to delete.

import SwiftUI

/// M4-01. Talks only to `BackupsListViewModel`; no repositories or Core Data here.
///
/// MOCK WIRING: until M1 stores trips and a shared backup repository exists, the screen shows
/// `PreviewSamples.trip` and in-memory sample backups (see `BackupsListViewModel.mocked()`).
struct BackupsListView: View {
    let trip: Trip

    @Environment(AppRouter.self) private var router
    @State private var viewModel: BackupsListViewModel
    /// False until the first load finishes, so the empty state does not flash before data arrives.
    @State private var hasLoaded = false

    /// With no view model, the screen uses the mock wiring below.
    init(viewModel: BackupsListViewModel? = nil, trip: Trip = PreviewSamples.trip) {
        _viewModel = State(initialValue: viewModel ?? .mocked())
        self.trip = trip
    }

    var body: some View {
        content
            .alert("Something went wrong", isPresented: isShowingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .task {
                await viewModel.load(trip: trip)
                hasLoaded = true
            }
    }

    @ViewBuilder
    private var content: some View {
        if !hasLoaded || (viewModel.isLoading && viewModel.isEmpty) {
            ProgressView("Loading backups…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColors.backgroundGradient)
                .navigationTitle("Backups")
        } else if viewModel.isEmpty {
            BackupsEmptyStateView(tripName: trip.name)
        } else {
            list
        }
    }

    private var list: some View {
        List {
            Text(viewModel.summaryText)
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
                .clearRow()

            ForEach(viewModel.sections) { section in
                Section {
                    ForEach(section.rows) { row in
                        Button {
                            open(row)
                        } label: {
                            BackupRowCard(row: row)
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Opens Use a backup")
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                delete(row)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .accessibilityLabel("Delete \(row.title)")
                        }
                        .clearRow()
                    }
                    // Used by the Edit button's delete mode.
                    .onDelete { offsets in
                        for index in offsets {
                            delete(section.rows[index])
                        }
                    }
                } header: {
                    DayHeader(title: section.header, count: section.rows.count)
                }
            }

            Text("Tap a backup to use it · Swipe left to delete")
                .font(.footnote)
                .foregroundStyle(AppColors.textSecondary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .clearRow()
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppColors.backgroundGradient)
        .navigationTitle("Backups")
        .toolbar {
            EditButton()
        }
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

    private func open(_ row: BackupRow) {
        guard let backup = viewModel.backup(for: row.id) else { return }
        router.present(.useBackup(backup: backup))
    }

    private func delete(_ row: BackupRow) {
        Task { await viewModel.delete(backupId: row.id) }
    }
}

/// "DAY 1 · FRI 13 NOV" with a small count badge.
private struct DayHeader: View {
    let title: String
    let count: Int

    var body: some View {
        // Wraps the badge under the title when the text is too large to fit on one line.
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) { label; badge }
            VStack(alignment: .leading, spacing: 4) { label; badge }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private var label: some View {
        Text(title)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(AppColors.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var badge: some View {
        Text("\(count)")
            .font(.caption2.weight(.bold))
            .foregroundStyle(AppColors.primary)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(AppColors.primary.opacity(0.15), in: Capsule())
            .accessibilityLabel(count == 1 ? "1 backup" : "\(count) backups")
    }
}

private extension View {
    /// A list row with no separator or white background, so the cards sit on the gradient.
    func clearRow() -> some View {
        listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
    }
}

// MARK: - Mock wiring

extension BackupsListViewModel {
    /// Sample backups for `PreviewSamples.trip`, kept for the app's lifetime so deletes stick.
    private static let mockBackups = MockBackupRepository(backups: [
        BackupOption(
            tripId: PreviewSamples.trip.id,
            content: .place(PreviewSamples.australianMuseum),
            dayDate: PreviewSamples.date(day: 13),
            savedAt: PreviewSamples.date(day: 10, hour: 9)
        ),
        BackupOption(
            tripId: PreviewSamples.trip.id,
            content: .place(PreviewSamples.queenVictoriaBuilding),
            dayDate: PreviewSamples.date(day: 14),
            savedAt: PreviewSamples.date(day: 10, hour: 10)
        ),
        BackupOption(
            tripId: PreviewSamples.trip.id,
            content: .activity(PreviewSamples.tarongaZoo),
            dayDate: PreviewSamples.date(day: 14),
            savedAt: PreviewSamples.date(day: 11, hour: 8)
        ),
    ])

    /// A view model on the in-memory sample backups. Swap in the real repository when it exists.
    static func mocked() -> BackupsListViewModel {
        mocked(repository: mockBackups)
    }

    static func mocked(repository: any BackupRepository) -> BackupsListViewModel {
        BackupsListViewModel(
            fetchBackups: FetchBackupsUseCase(repository: repository),
            removeBackup: RemoveBackupUseCase(repository: repository)
        )
    }
}

// MARK: - Previews

#Preview("List") {
    NavigationStack { BackupsListView() }
        .environment(AppRouter())
}

#Preview("Empty") {
    NavigationStack { BackupsListView(viewModel: .mocked(repository: MockBackupRepository())) }
        .environment(AppRouter())
}

#Preview("List – Dark") {
    NavigationStack { BackupsListView() }
        .environment(AppRouter())
        .preferredColorScheme(.dark)
}
