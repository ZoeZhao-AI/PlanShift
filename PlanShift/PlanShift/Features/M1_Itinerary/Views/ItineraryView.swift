
import SwiftUI

// Module: M1 - Itinerary Management

@MainActor
struct ItineraryView: View {

    @Environment(AppRouter.self) private var router
    @State private var viewModel: ItineraryViewModel
    @State private var selectedDay = 0

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
        .m1ScreenBackground()
        .navigationTitle(viewModel.trip?.name ?? "Itinerary")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if viewModel.trip != nil {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        router.itineraryPath.append(.activityForm)
                    } label: {
                        Label("Add activity", systemImage: "plus")
                    }
                }
            }
        }
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
        // Replace (banner on) and Undo (banner off) both change the stored itinerary behind this screen.
        .onChange(of: router.showsUpdatedItineraryBanner) {
            Task {
                await viewModel.loadItinerary()
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
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Empty State

    private var noTripContent: some View {
        ContentUnavailableView {
            Label("No trip yet", systemImage: "suitcase")
        } description: {
            Text("Create a trip, then add the places you plan to visit each day.")
        } actions: {
            Button {
                router.itineraryPath.append(.createTrip)
            } label: {
                Label("Create your first trip", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.ctaFill)
            .tint(AppColors.ctaFill)
            .controlSize(.large)
        }
    }

    // MARK: - Itinerary Home

    private func tripContent(_ trip: Trip) -> some View {
        let calendar = Calendar.current
        let currentDate = calendar.date(
            byAdding: .day,
            value: selectedDay,
            to: calendar.startOfDay(for: trip.startDate)
        ) ?? trip.startDate
        let dayActivities = viewModel.activities
            .filter { calendar.isDate($0.date, inSameDayAs: currentDate) }
            .sorted { $0.startTime < $1.startTime }

        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(
                    "\(trip.startDate.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))) – "
                    + "\(trip.endDate.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)

                daySelector(trip)

                if dayActivities.isEmpty {
                    ContentUnavailableView {
                        Label("No activities for this day", systemImage: "calendar.badge.plus")
                    } actions: {
                        Button("Add activity") {
                            router.itineraryPath.append(.activityForm)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }
                    .padding(.top, 24)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(dayActivities) { activity in
                            activityCard(activity)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Day Selector

    private func daySelector(_ trip: Trip) -> some View {
        let calendar = Calendar.current
        let totalDays = max(
            1,
            (calendar.dateComponents(
                [.day],
                from: calendar.startOfDay(for: trip.startDate),
                to: calendar.startOfDay(for: trip.endDate)
            ).day ?? 0) + 1
        )

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(0..<totalDays, id: \.self) { day in
                    let date = calendar.date(byAdding: .day, value: day, to: trip.startDate) ?? trip.startDate
                    let isSelected = selectedDay == day
                    Button {
                        selectedDay = day
                    } label: {
                        VStack(spacing: 2) {
                            Text("Day \(day + 1)")
                                .font(.subheadline.weight(.semibold))
                            Text(calendar.isDateInToday(date) ? "Today" : date.formatted(.dateTime.weekday(.abbreviated)))
                                .font(.caption)
                        }
                        .padding(.horizontal, 16)
                        .frame(minWidth: 80, minHeight: 44)
                        .padding(.vertical, 4)
                        .foregroundStyle(isSelected ? Color.white : Color.primary)
                        .background(
                            isSelected ? AppColors.ctaFill : Color(.secondarySystemGroupedBackground),
                            in: Capsule()
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Day \(day + 1), \(date.formatted(.dateTime.weekday(.wide).day().month(.wide)))")
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
    }

    // MARK: - Activity Card

    private func activityCard(_ activity: ItineraryActivity) -> some View {
        let isFinished = activity.endTime < Date()
        let timeRange = "\(activity.startTime.formatted(date: .omitted, time: .shortened)) – "
            + "\(activity.endTime.formatted(date: .omitted, time: .shortened))"

        return Button {
            router.itineraryPath.append(.activityDetail(activityId: activity.id))
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                ActivityPhotoView(activity: activity)
                    .frame(height: 140)
                    .frame(maxWidth: .infinity)
                    .overlay(alignment: .topLeading) {
                        Text(timeRange)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.regularMaterial, in: Capsule())
                            .padding(10)
                    }
                    .clipped()

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(activity.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)

                        Spacer(minLength: 8)

                        Text(isFinished ? "Done" : "Up next")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(isFinished ? Color.secondary : AppColors.actionText)
                    }

                    HStack(spacing: 8) {
                        SettingPill(setting: activity.setting)

                        Text(activity.locationName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        Spacer(minLength: 0)

                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.tertiary)
                            .accessibilityHidden(true)
                    }
                }
                .padding(14)
            }
            .m1Card()
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(activity.name), \(timeRange), \(activity.setting.title), \(activity.locationName), \(isFinished ? "done" : "up next")")
        .accessibilityHint("Opens activity details")
        .accessibilityAddTraits(.isButton)
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
