
import SwiftUI

// Module: M1 - Itinerary Management

@MainActor
struct ItineraryView: View {

    @Environment(AppRouter.self) private var router
    @State private var viewModel: ItineraryViewModel
    @State private var selectedDay = 0

    private let primaryGreen = Color(
        red: 0.02, green: 0.49, blue: 0.43
    )

    private let darkText = Color(
        red: 0.08, green: 0.14, blue: 0.25
    )

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
        .foregroundStyle(darkText)
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
                set: {
                    if !$0 {
                        viewModel.errorMessage = nil
                    }
                }
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

    // MARK: - Empty State

    private var noTripContent: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Itinerary")
                    .font(.system(size: 27, weight: .bold))

                Text("No trip yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 20)

            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "cloud.sun.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(primaryGreen)

                Text("No activities yet")
                    .font(.headline)

                Text(
                    "Start by creating your trip, then add the places you plan to visit each day."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

                Button {
                    router.itineraryPath.append(.createTrip)
                } label: {
                    Label(
                        "Create your first trip",
                        systemImage: "plus"
                    )
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        primaryGreen,
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                }
                .buttonStyle(.plain)
            }

            Spacer()
            Spacer()
        }
    }

    // MARK: - Itinerary Home

    private func tripContent(_ trip: Trip) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(trip.name)
                            .font(.system(size: 27, weight: .bold))

                        HStack(spacing: 5) {
                            Text(
                                trip.startDate.formatted(
                                    .dateTime.weekday(.abbreviated)
                                        .day().month(.abbreviated)
                                )
                            )

                            Text("–")

                            Text(
                                trip.endDate.formatted(
                                    .dateTime.weekday(.abbreviated)
                                        .day().month(.abbreviated)
                                )
                            )

                            Text("· Day \(selectedDay + 1)")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        router.itineraryPath.append(.activityForm)
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                            .foregroundStyle(primaryGreen)
                            .frame(width: 36, height: 36)
                            .background(.white, in: Circle())
                    }
                }

                daySelector(trip)

                let currentDate = Calendar.current.date(
                    byAdding: .day,
                    value: selectedDay,
                    to: Calendar.current.startOfDay(
                        for: trip.startDate
                    )
                ) ?? trip.startDate

                let dayActivities = viewModel.activities
                    .filter {
                        Calendar.current.isDate(
                            $0.date,
                            inSameDayAs: currentDate
                        )
                    }
                    .sorted {
                        $0.startTime < $1.startTime
                    }

                if dayActivities.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 42))
                            .foregroundStyle(primaryGreen)

                        Text("No activities for this day")
                            .font(.headline)

                        Button("Add Activity") {
                            router.itineraryPath.append(.activityForm)
                        }
                        .font(.subheadline.bold())
                        .foregroundStyle(primaryGreen)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 55)
                } else {
                    LazyVStack(spacing: 9) {
                        ForEach(dayActivities) { activity in
                            activityCard(activity)
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    // MARK: - Day Selector

    private func daySelector(_ trip: Trip) -> some View {
        let totalDays = max(
            1,
            (Calendar.current.dateComponents(
                [.day],
                from: Calendar.current.startOfDay(
                    for: trip.startDate
                ),
                to: Calendar.current.startOfDay(
                    for: trip.endDate
                )
            ).day ?? 0) + 1
        )

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(0..<totalDays, id: \.self) { day in
                    Button {
                        selectedDay = day
                    } label: {
                        VStack(spacing: 3) {
                            Text("Day \(day + 1)")
                                .font(.caption.bold())

                            let date = Calendar.current.date(
                                byAdding: .day,
                                value: day,
                                to: trip.startDate
                            ) ?? trip.startDate

                            Text(
                                Calendar.current.isDateInToday(date)
                                    ? "Today"
                                    : date.formatted(
                                        .dateTime.weekday(.abbreviated)
                                    )
                            )
                            .font(.caption2)
                        }
                        .frame(width: 98)
                        .padding(.vertical, 8)
                        .foregroundStyle(
                            selectedDay == day ? .white : darkText
                        )
                        .background(
                            selectedDay == day
                                ? primaryGreen
                                : Color.white,
                            in: RoundedRectangle(cornerRadius: 9)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
        }
        .background(
            .white.opacity(0.65),
            in: RoundedRectangle(cornerRadius: 12)
        )
    }

    // MARK: - Activity Card

    private func activityCard(
        _ activity: ItineraryActivity
    ) -> some View {

        let isFinished = activity.endTime < Date()

        return Button {
            router.itineraryPath.append(
                .activityDetail(activityId: activity.id)
            )
        } label: {
            VStack(alignment: .leading, spacing: 0) {

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.72, green: 0.88, blue: 0.98),
                                    Color(red: 0.48, green: 0.79, blue: 0.72)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Image(systemName: "mountain.2.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(
                            primaryGreen.opacity(0.45)
                        )
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity
                        )

                    Text(
                        activity.startTime.formatted(
                            date: .omitted,
                            time: .shortened
                        )
                        + " – " +
                        activity.endTime.formatted(
                            date: .omitted,
                            time: .shortened
                        )
                    )
                    .font(.caption2.bold())
                    .foregroundStyle(darkText)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.9), in: Capsule())
                    .padding(8)
                }
                .frame(height: 100)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(activity.name)
                            .font(.subheadline.bold())
                            .foregroundStyle(darkText)

                        Spacer()

                        Text(isFinished ? "Done" : "Up next")
                            .font(.caption2.bold())
                            .foregroundStyle(
                                isFinished ? .gray : primaryGreen
                            )
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                isFinished
                                    ? Color.gray.opacity(0.12)
                                    : primaryGreen.opacity(0.1),
                                in: Capsule()
                            )
                    }

                    HStack(spacing: 6) {
                        Text(activity.setting.title)
                            .font(.caption2.bold())
                            .foregroundStyle(primaryGreen)

                        Text(activity.locationName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(10)
            }
            .background(
                .white,
                in: RoundedRectangle(cornerRadius: 14)
            )
        }
        .buttonStyle(.plain)
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
