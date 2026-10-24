
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
        .m1ScreenBackground()
        .navigationBarBackButtonHidden(true)
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

        return Form {
            Section {
                TextField("Activity name", text: $model.name)
                    .textInputAutocapitalization(.words)
                    .frame(minHeight: 44)

                TextField("Search location", text: $model.locationName)
                    .frame(minHeight: 44)
                    .onChange(of: model.locationName) {
                        model.locationTextChanged()
                    }

                if !model.hasLocation {
                    ForEach(suggestions(for: model.locationName)) { place in
                        Button {
                            model.apply(place)
                        } label: {
                            HStack(spacing: 12) {
                                PlaceArtworkView(
                                    name: place.name,
                                    setting: place.setting,
                                    imageName: place.imageName
                                )
                                .frame(width: 44, height: 44)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(place.name)
                                        .font(.body)
                                        .foregroundStyle(.primary)

                                    Text("\(place.suburb) · \(place.setting.title)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        }
                    }
                }
            } footer: {
                if !model.hasLocation {
                    Text("Choose a place from the suggestions to set the location.")
                }
            }

            Section {
                DatePicker("Date", selection: $model.date, displayedComponents: .date)
                DatePicker("Start time", selection: $model.startTime, displayedComponents: .hourAndMinute)
                DatePicker("End time", selection: $model.endTime, displayedComponents: .hourAndMinute)
            } footer: {
                if invalidTime {
                    Label("End time must be after start time", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }
            }

            Section {
                Picker("Setting", selection: $model.setting) {
                    Text("Indoor").tag(ActivitySetting.indoor)
                    Text("Outdoor").tag(ActivitySetting.outdoor)
                }
                .pickerStyle(.segmented)

                LabeledContent("Est. cost (AUD)") {
                    TextField("0", value: $model.estimatedCost, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
            } footer: {
                Text("Cost is per person.")
            }

            if let errorMessage = model.errorMessage {
                Section {
                    Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(model.isEditing ? "Edit Activity" : "New Activity")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { await saveActivity(model) }
                }
                .disabled(model.isSaving || !model.hasLocation || invalidTime)
            }
        }
        .disabled(model.isSaving)
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
