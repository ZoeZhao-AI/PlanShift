// Module: M1 – placeholder for M1-01 Itinerary.


import SwiftUI

// Module: M1 - Itinerary Management

@MainActor
struct ItineraryView: View {

    @Environment(AppRouter.self) private var router

    @State private var viewModel: ItineraryViewModel

    init(
        tripRepository: any TripRepository =
            M1InMemoryTripRepository.shared,
        activityRepository: any ActivityRepository =
            M1InMemoryActivityRepository.shared
    ) {
        _viewModel = State(
            initialValue: ItineraryViewModel(
                tripRepository: tripRepository,
                fetchItineraryUseCase: FetchItineraryUseCase(
                    repository: activityRepository
                )
            )
        )
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading itinerary...")

            } else if let trip = viewModel.trip {
                tripContent(trip)

            } else {
                noTripContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(AppColors.textPrimary)
        .background(AppColors.backgroundGradient)
        .navigationTitle("Itinerary")
        .task {
            await viewModel.loadItinerary()
        }
        .onChange(of: router.itineraryPath.count) {
            oldCount, newCount in

            if oldCount > 0 && newCount == 0 {
                Task {
                    await viewModel.loadItinerary()
                }
            }
        }
        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .safeAreaInset(edge: .bottom) {
            if router.showsUpdatedItineraryBanner {
                UpdatedItineraryBanner()
            }
        }
    }

    private var noTripContent: some View {
        ContentUnavailableView {
            Label(
                "No Trip Yet",
                systemImage: "calendar.badge.plus"
            )
        } description: {
            Text("Create a trip to start planning your itinerary.")
        } actions: {
            Button("Create Trip") {
                router.itineraryPath.append(.createTrip)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    private func tripContent(_ trip: Trip) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                VStack(alignment: .leading, spacing: 8) {
                    Text(trip.name)
                        .font(.title.bold())

                    Text(
                        "\(trip.startDate.formatted(date: .abbreviated, time: .omitted))"
                        + " – "
                        + "\(trip.endDate.formatted(date: .abbreviated, time: .omitted))"
                    )
                    .font(.subheadline)
                }

                Divider()

                HStack {
                    Text("Activities")
                        .font(.title2.bold())

                    Spacer()

                    Button {
                        router.itineraryPath.append(.activityForm)
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                }

                if viewModel.activities.isEmpty {
                    ContentUnavailableView {
                        Label(
                            "No Activities Yet",
                            systemImage: "calendar"
                        )
                    } description: {
                        Text("Add your first activity to this trip.")
                    } actions: {
                        Button("Add Activity") {
                            router.itineraryPath.append(.activityForm)
                        }
                        .buttonStyle(.bordered)
                    }

                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.activities) { activity in
                            Button {
                                router.itineraryPath.append(
                                    .activityDetail(activityId: activity.id)
                                )
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(activity.name)
                                            .font(.headline)

                                        Text(activity.locationName)
                                            .font(.subheadline)

                                        Text(
                                            activity.startTime.formatted(
                                                date: .abbreviated,
                                                time: .shortened
                                            )
                                        )
                                        .font(.caption)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    .regularMaterial,
                                    in: RoundedRectangle(cornerRadius: 12)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding()
        }
    }
}

#Preview {
    NavigationStack {
        ItineraryView(
            tripRepository: M1InMemoryTripRepository(),
            activityRepository: M1InMemoryActivityRepository()
        )
    }
    .environment(AppRouter())
}
