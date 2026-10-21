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
        .foregroundStyle(AppColors.textPrimary)
        .background(AppColors.backgroundGradient)
        .navigationTitle("Activity Detail")
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
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Cancel") {
                                isShowingEditForm = false
                            }
                        }
                    }
                }
            }
        }
        .deleteConfirmationAlert(
            isPresented: $isShowingDeleteConfirmation
        ) {
            Task {
                await deleteActivity()
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

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                Text(activity.name)
                    .font(.title.bold())

                Divider()

                detailRow(
                    "Date",
                    activity.date.formatted(
                        date: .abbreviated,
                        time: .omitted
                    )
                )

                detailRow(
                    "Start time",
                    activity.startTime.formatted(
                        date: .omitted,
                        time: .shortened
                    )
                )

                detailRow(
                    "End time",
                    activity.endTime.formatted(
                        date: .omitted,
                        time: .shortened
                    )
                )

                detailRow(
                    "Location",
                    activity.locationName
                )

                detailRow(
                    "Setting",
                    activity.setting.title
                )

                detailRow(
                    "Estimated cost",
                    "AUD \(activity.estimatedCost)"
                )

                Divider()

                Button("Plan Disrupted") {
                    router.present(
                        .disruptionFlow(activity: activity)
                    )
                }
                .buttonStyle(.bordered)

                Button("Edit Activity") {
                    isShowingEditForm = true
                }
                .buttonStyle(.borderedProminent)

                Button(
                    "Delete Activity",
                    role: .destructive
                ) {
                    isShowingDeleteConfirmation = true
                }
                .buttonStyle(.bordered)
                .disabled(isDeleting)

                if isDeleting {
                    ProgressView("Deleting activity...")
                }
            }
            .padding()
        }
    }

    private func detailRow(
        _ title: String,
        _ value: String
    ) -> some View {

        HStack(alignment: .top) {
            Text(title)
                .foregroundStyle(AppColors.textSecondary)

            Spacer()

            Text(value)
                .multilineTextAlignment(.trailing)
        }
    }

    private func loadActivity() async {

        isLoading = true
        errorMessage = nil
        activity = nil

        defer {
            isLoading = false
        }

        do {
            guard let trip = try await
                tripRepository.fetchCurrentTrip()
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
            try await useCase.execute(
                id: activityId
            )

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
