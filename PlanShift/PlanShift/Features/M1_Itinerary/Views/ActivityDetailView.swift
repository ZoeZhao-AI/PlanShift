
import SwiftUI

// Module: M1 - Activity Detail

@MainActor
struct ActivityDetailView: View {

    let activityId: UUID

    @Environment(AppRouter.self) private var router

    @State private var activity: ItineraryActivity?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var isShowingDeleteConfirmation = false
    @State private var isShowingEditForm = false
    @State private var isDeleting = false

    private let repository: any ActivityRepository
    private let tripRepository: any TripRepository

    init(
        activityId: UUID,
        repository: any ActivityRepository =
            M1InMemoryActivityRepository.shared,
        tripRepository: any TripRepository =
            M1InMemoryTripRepository.shared
    ) {
        self.activityId = activityId
        self.repository = repository
        self.tripRepository = tripRepository
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading activity...")
            } else if let activity {
                activityContent(activity)
            } else {
                ContentUnavailableView(
                    "Activity Not Found",
                    systemImage: "exclamationmark.triangle",
                    description: Text(
                        errorMessage ?? "This activity could not be found."
                    )
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .m1ScreenBackground()
        .navigationTitle(activity?.name ?? "Activity")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadActivity()
        }
        .sheet(
            isPresented: $isShowingEditForm,
            onDismiss: {
                Task {
                    await loadActivity()
                }
            }
        ) {
            NavigationStack {
                if let activity {
                    ActivityFormView(
                        tripRepository: tripRepository,
                        activityRepository: repository,
                        existingActivity: activity
                    )
                }
            }
        }
        .alert(
            "Error",
            isPresented: Binding(
                get: {
                    errorMessage != nil && activity != nil
                },
                set: {
                    if !$0 {
                        errorMessage = nil
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func activityContent(
        _ activity: ItineraryActivity
    ) -> some View {
        let minutes = max(0, Int(activity.endTime.timeIntervalSince(activity.startTime) / 60))
        let durationText = Duration.seconds(minutes * 60)
            .formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))

        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ActivityPhotoView(activity: activity)
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)
                    .overlay(alignment: .bottomLeading) {
                        SettingPill(setting: activity.setting)
                            .padding(12)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text(activity.name)
                        .font(.title.bold())

                    Label(activity.locationName, systemImage: "mappin.and.ellipse")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Label(
                        activity.date.formatted(date: .complete, time: .omitted),
                        systemImage: "calendar"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)

                HStack(alignment: .top, spacing: 10) {
                    infoCard(
                        "Starts",
                        activity.startTime.formatted(date: .omitted, time: .shortened),
                        "until " + activity.endTime.formatted(date: .omitted, time: .shortened)
                    )
                    infoCard("Duration", durationText, "planned")
                    infoCard(
                        "Est. cost",
                        activity.estimatedCost == 0
                            ? "Free"
                            : activity.estimatedCost.formatted(.currency(code: "AUD")),
                        "per person"
                    )
                }

                Button {
                    router.present(.disruptionFlow(activity: activity))
                } label: {
                    Label("Find alternatives", systemImage: "arrow.left.arrow.right")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
            .tint(AppColors.ctaFill)
            .tint(AppColors.ctaFill)
                .controlSize(.large)

                HStack(spacing: 12) {
                    Button {
                        isShowingEditForm = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)

                    Button(role: .destructive) {
                        isShowingDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .disabled(isDeleting)
                }

                if isDeleting {
                    ProgressView("Deleting activity...")
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(16)
        }
        .alert(
            "Delete \"\(activity.name)\"?",
            isPresented: $isShowingDeleteConfirmation
        ) {
            Button("Cancel", role: .cancel) {}

            Button("Delete", role: .destructive) {
                Task {
                    await deleteActivity()
                }
            }
        } message: {
            Text(
                "This removes it from \(activity.date.formatted(.dateTime.weekday(.wide).day().month(.wide))). Your saved backups won't change."
            )
        }
    }

    private func infoCard(
        _ title: String,
        _ value: String,
        _ subtitle: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .minimumScaleFactor(0.8)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(12)
        .m1Card(cornerRadius: 14)
        .accessibilityElement(children: .combine)
    }

    private func loadActivity() async {

        isLoading = true
        errorMessage = nil
        activity = nil

        defer {
            isLoading = false
        }

        do {
            guard let trip =
                try await tripRepository.fetchCurrentTrip()
            else {
                errorMessage = "No trip found."
                return
            }

            let activities = try await repository.fetchActivities(
                tripId: trip.id
            )

            activity = activities.first {
                $0.id == activityId
            }

            if activity == nil {
                errorMessage = "This activity could not be found."
            }

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteActivity() async {

        guard !isDeleting else {
            return
        }

        isDeleting = true

        defer {
            isDeleting = false
        }

        let useCase = DeleteActivityUseCase(
            repository: repository
        )

        do {
            try await useCase.execute(id: activityId)

            if !router.itineraryPath.isEmpty {
                router.itineraryPath.removeLast()
            }

        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        ActivityDetailView(
            activityId: PreviewSamples.coastalWalk.id
        )
    }
    .environment(AppRouter())
}
