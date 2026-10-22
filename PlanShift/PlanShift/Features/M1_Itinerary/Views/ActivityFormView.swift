
import SwiftUI

// Module: M1 - Add / Edit Activity

@MainActor
struct ActivityFormView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: ActivityFormViewModel?
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var allPlaces: [Place] = []

    private let tripRepository: any TripRepository
    private let activityRepository: any ActivityRepository
    private let existingActivity: ItineraryActivity?
    private let placeRepository: any PlaceRepository

    private let primaryGreen = Color(
        red: 0.02, green: 0.49, blue: 0.43
    )

    private let backgroundTop = Color(
        red: 0.91, green: 0.96, blue: 1.0
    )

    private let backgroundBottom = Color(
        red: 0.89, green: 0.98, blue: 0.94
    )

    init(
        tripRepository: any TripRepository =
            M1InMemoryTripRepository.shared,
        activityRepository: any ActivityRepository =
            M1InMemoryActivityRepository.shared,
        existingActivity: ItineraryActivity? = nil,
        placeRepository: any PlaceRepository =
            BundledPlaceRepository()
    ) {
        self.tripRepository = tripRepository
        self.activityRepository = activityRepository
        self.existingActivity = existingActivity
        self.placeRepository = placeRepository
    }

    var body: some View {
        Group {
            if let viewModel {
                activityForm(viewModel)
            } else if isLoading {
                ProgressView("Loading trip...")
            } else {
                ContentUnavailableView(
                    "Unable to Load Activity",
                    systemImage: "exclamationmark.triangle",
                    description: Text(
                        loadError ?? "Please create a trip first."
                    )
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [backgroundTop, backgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .task {
            await loadTrip()
            allPlaces =
                (try? await placeRepository.fetchAllPlaces()) ?? []
        }
    }

    private func activityForm(
        _ viewModel: ActivityFormViewModel
    ) -> some View {

        @Bindable var model = viewModel

        let invalidTime = model.endTime <= model.startTime

        return VStack(spacing: 0) {

            // Header
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundStyle(primaryGreen)

                Spacer()

                Text(
                    model.isEditing
                        ? "Edit Activity"
                        : "New Activity"
                )
                .font(.headline)

                Spacer()

                Button("Save") {
                    Task {
                        await saveActivity(model)
                    }
                }
                .fontWeight(.semibold)
                .foregroundStyle(primaryGreen)
                .disabled(model.isSaving || !model.hasLocation)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)

            ScrollView {
                VStack(spacing: 12) {

                    // Name and Location
                    VStack(spacing: 0) {

                        HStack {
                            Text("Name")
                                .foregroundStyle(.secondary)

                            TextField(
                                "Activity name",
                                text: $model.name
                            )
                            .multilineTextAlignment(.trailing)
                        }
                        .padding(14)

                        Divider()

                        HStack {
                            Text("Location")
                                .foregroundStyle(.secondary)

                            TextField(
                                "Search location",
                                text: $model.locationName
                            )
                            .multilineTextAlignment(.trailing)
                            .onChange(of: model.locationName) {
                                model.locationTextChanged()
                            }
                        }
                        .padding(14)

                        if !model.hasLocation {
                            ForEach(
                                suggestions(for: model.locationName)
                            ) { place in
                                Divider()

                                Button {
                                    model.apply(place)
                                } label: {
                                    VStack(
                                        alignment: .leading,
                                        spacing: 3
                                    ) {
                                        Text(place.name)
                                            .font(.subheadline.bold())

                                        Text(
                                            "\(place.suburb) · " +
                                            place.setting.title
                                        )
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    }
                                    .frame(
                                        maxWidth: .infinity,
                                        alignment: .leading
                                    )
                                    .padding(12)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .background(
                        .white,
                        in: RoundedRectangle(cornerRadius: 15)
                    )

                    // Date and Time
                    VStack(spacing: 0) {

                        DatePicker(
                            "Date",
                            selection: $model.date,
                            displayedComponents: .date
                        )
                        .padding(12)

                        Divider()

                        DatePicker(
                            "Start time",
                            selection: $model.startTime,
                            displayedComponents: .hourAndMinute
                        )
                        .padding(12)

                        Divider()

                        DatePicker(
                            "End time",
                            selection: $model.endTime,
                            displayedComponents: .hourAndMinute
                        )
                        .padding(12)
                        .background(
                            invalidTime
                                ? Color.red.opacity(0.07)
                                : Color.clear
                        )
                    }
                    .background(
                        .white,
                        in: RoundedRectangle(cornerRadius: 15)
                    )

                    if invalidTime {
                        Label(
                            "End time must be after start time",
                            systemImage: "exclamationmark.triangle"
                        )
                        .font(.caption)
                        .foregroundStyle(.red)
                        .frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )
                    }

                    // Indoor / Outdoor
                    VStack(spacing: 0) {

                        HStack {
                            Text("Setting")
                                .font(.subheadline)

                            Spacer()

                            HStack(spacing: 4) {
                                settingButton(
                                    "Indoor",
                                    setting: .indoor,
                                    model: model
                                )

                                settingButton(
                                    "Outdoor",
                                    setting: .outdoor,
                                    model: model
                                )
                            }
                        }
                        .padding(12)

                        Divider()

                        HStack {
                            Text("Est. cost")
                                .font(.subheadline)

                            Spacer()

                            Text("$")
                                .foregroundStyle(.secondary)

                            TextField(
                                "0",
                                value: $model.estimatedCost,
                                format: .number
                            )
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 65)

                            Text("per person")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(12)
                    }
                    .background(
                        .white,
                        in: RoundedRectangle(cornerRadius: 15)
                    )

                    if let errorMessage = model.errorMessage {
                        Label(
                            errorMessage,
                            systemImage: "exclamationmark.circle"
                        )
                        .font(.footnote)
                        .foregroundStyle(.red)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .disabled(model.isSaving)
    }

    private func settingButton(
        _ title: String,
        setting: ActivitySetting,
        model: ActivityFormViewModel
    ) -> some View {
        Button {
            model.setting = setting
        } label: {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(
                    model.setting == setting
                        ? .white
                        : .primary
                )
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    model.setting == setting
                        ? primaryGreen
                        : Color.white,
                    in: RoundedRectangle(cornerRadius: 9)
                )
        }
        .buttonStyle(.plain)
    }

    private func suggestions(for text: String) -> [Place] {
        let query = text.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !query.isEmpty else {
            return []
        }

        return Array(
            allPlaces.filter {
                $0.name.localizedCaseInsensitiveContains(query)
                || $0.suburb.localizedCaseInsensitiveContains(query)
            }
            .prefix(5)
        )
    }

    private func saveActivity(
        _ model: ActivityFormViewModel
    ) async {

        guard !model.isSaving else {
            return
        }

        let calendar = Calendar.current

        let startComponents = calendar.dateComponents(
            [.hour, .minute],
            from: model.startTime
        )

        let endComponents = calendar.dateComponents(
            [.hour, .minute],
            from: model.endTime
        )

        model.startTime = calendar.date(
            bySettingHour: startComponents.hour ?? 0,
            minute: startComponents.minute ?? 0,
            second: 0,
            of: model.date
        ) ?? model.startTime

        model.endTime = calendar.date(
            bySettingHour: endComponents.hour ?? 0,
            minute: endComponents.minute ?? 0,
            second: 0,
            of: model.date
        ) ?? model.endTime

        let succeeded = await model.save()

        if succeeded {
            dismiss()
        }
    }

    private func loadTrip() async {

        guard viewModel == nil else {
            return
        }

        isLoading = true
        loadError = nil

        defer {
            isLoading = false
        }

        do {
            guard let trip =
                try await tripRepository.fetchCurrentTrip()
            else {
                loadError = "Please create a trip first."
                return
            }

            if let existingActivity,
               existingActivity.tripId != trip.id {
                loadError =
                    "This activity belongs to another trip."
                return
            }

            viewModel = ActivityFormViewModel(
                tripId: trip.id,
                repository: activityRepository,
                existingActivity: existingActivity
            )

            if existingActivity == nil {
                viewModel?.date = trip.startDate
            }

        } catch {
            loadError = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        ActivityFormView(
            tripRepository: M1InMemoryTripRepository(),
            activityRepository: M1InMemoryActivityRepository()
        )
    }
}
