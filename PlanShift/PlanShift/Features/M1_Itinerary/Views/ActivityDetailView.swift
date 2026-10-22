
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

    private let primaryGreen = Color(
        red: 0.02, green: 0.49, blue: 0.43
    )

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
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.91, green: 0.96, blue: 1.0),
                    Color(red: 0.89, green: 0.98, blue: 0.94)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .toolbar(.hidden, for: .navigationBar)
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

        ScrollView {
            VStack(alignment: .leading, spacing: 14) {

                // Back navigation
                Button {
                    if !router.itineraryPath.isEmpty {
                        router.itineraryPath.removeLast()
                    }
                } label: {
                    Label("Day 1", systemImage: "chevron.left")
                        .font(.subheadline)
                        .foregroundStyle(primaryGreen)
                }
                .padding(.bottom, 4)

                // Activity illustration placeholder
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 17)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.65, green: 0.86, blue: 0.98),
                                    Color(red: 0.41, green: 0.77, blue: 0.58)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Image(systemName: "mountain.2.fill")
                        .font(.system(size: 85))
                        .foregroundStyle(.green.opacity(0.55))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    Text(activity.setting.title)
                        .font(.caption.bold())
                        .foregroundStyle(primaryGreen)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.white, in: Capsule())
                        .padding(12)
                }
                .frame(height: 195)

                // Activity title
                Text(activity.name)
                    .font(.system(size: 27, weight: .bold))

                Label(
                    activity.locationName,
                    systemImage: "mappin"
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                Text(
                    activity.date.formatted(
                        date: .abbreviated,
                        time: .omitted
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                // Three information cards
                HStack(spacing: 8) {

                    infoCard(
                        "Starts",
                        activity.startTime.formatted(
                            date: .omitted,
                            time: .shortened
                        ),
                        "until " +
                        activity.endTime.formatted(
                            date: .omitted,
                            time: .shortened
                        )
                    )

                    let duration = max(
                        0,
                        Int(
                            activity.endTime.timeIntervalSince(
                                activity.startTime
                            ) / 60
                        )
                    )

                    infoCard(
                        "Duration",
                        "\(duration / 60) hrs " +
                        "\(duration % 60) min",
                        "planned"
                    )

                    infoCard(
                        "Est. cost",
                        "$\(activity.estimatedCost)",
                        "per person"
                    )
                }

                // Find alternatives
                Button {
                    router.present(
                        .disruptionFlow(activity: activity)
                    )
                } label: {
                    Label(
                        "Find alternatives",
                        systemImage: "arrow.left.arrow.right"
                    )
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .foregroundStyle(.white)
                    .background(
                        primaryGreen,
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                }
                .buttonStyle(.plain)

                // Edit and Delete
                HStack(spacing: 10) {

                    Button {
                        isShowingEditForm = true
                    } label: {
                        Label(
                            "Edit",
                            systemImage: "pencil"
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(
                            .white,
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                    }
                    .foregroundStyle(.primary)

                    Button {
                        isShowingDeleteConfirmation = true
                    } label: {
                        Label(
                            "Delete",
                            systemImage: "trash"
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(
                            .white,
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                    }
                    .foregroundStyle(.red)
                    .disabled(isDeleting)
                }

                if isDeleting {
                    ProgressView("Deleting activity...")
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
                "This removes it from Day 1. Your saved backups won't change."
            )
        }
    }

    private func infoCard(
        _ title: String,
        _ value: String,
        _ subtitle: String
    ) -> some View {

        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            .white,
            in: RoundedRectangle(cornerRadius: 12)
        )
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
