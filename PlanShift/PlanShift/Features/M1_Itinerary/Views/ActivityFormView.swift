import SwiftUI

// Module: M1 - Add / Edit Activity

@MainActor
struct ActivityFormView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: ActivityFormViewModel?
    @State private var isLoading = true
    @State private var loadError: String?

    private let tripRepository: any TripRepository
    private let activityRepository: any ActivityRepository
    private let existingActivity: ItineraryActivity?

    init(
        tripRepository: any TripRepository =
            M1InMemoryTripRepository.shared,
        activityRepository: any ActivityRepository =
            M1InMemoryActivityRepository.shared,
        existingActivity: ItineraryActivity? = nil
    ) {
        self.tripRepository = tripRepository
        self.activityRepository = activityRepository
        self.existingActivity = existingActivity
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
        .background(AppColors.backgroundGradient)
        .navigationTitle(
            existingActivity == nil
                ? "Add Activity"
                : "Edit Activity"
        )
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadTrip()
        }
    }

    private func activityForm(
        _ model: ActivityFormViewModel
    ) -> some View {

        @Bindable var model = model

        return Form {

            Section("Activity details") {
                TextField(
                    "Activity name",
                    text: $model.name
                )

                TextField(
                    "Location",
                    text: $model.locationName
                )
            }

            Section("Date and time") {
                DatePicker(
                    "Date",
                    selection: $model.date,
                    displayedComponents: .date
                )

                DatePicker(
                    "Start time",
                    selection: $model.startTime,
                    displayedComponents: .hourAndMinute
                )

                DatePicker(
                    "End time",
                    selection: $model.endTime,
                    displayedComponents: .hourAndMinute
                )
            }

            Section("Location coordinates") {
                LabeledContent("Latitude") {
                    TextField(
                        "Latitude",
                        value: $model.latitude,
                        format: .number
                    )
                    .keyboardType(.numbersAndPunctuation)
                    .multilineTextAlignment(.trailing)
                }

                LabeledContent("Longitude") {
                    TextField(
                        "Longitude",
                        value: $model.longitude,
                        format: .number
                    )
                    .keyboardType(.numbersAndPunctuation)
                    .multilineTextAlignment(.trailing)
                }
            }

            Section("Activity preferences") {
                Picker(
                    "Setting",
                    selection: $model.setting
                ) {
                    Text("Indoor")
                        .tag(ActivitySetting.indoor)

                    Text("Outdoor")
                        .tag(ActivitySetting.outdoor)
                }

                LabeledContent("Estimated cost (AUD)") {
                    TextField(
                        "Cost",
                        value: $model.estimatedCost,
                        format: .number
                    )
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                }
            }

            if let errorMessage = model.errorMessage {
                Section {
                    Label(
                        errorMessage,
                        systemImage: "exclamationmark.circle"
                    )
                    .foregroundStyle(.red)
                }
            }

            Section {
                Button {
                    Task {
                        await saveActivity(model)
                    }
                } label: {
                    HStack {
                        Spacer()

                        if model.isSaving {
                            ProgressView()
                        }

                        Text(
                            model.isSaving
                                ? "Saving..."
                                : (
                                    model.isEditing
                                        ? "Save Changes"
                                        : "Save Activity"
                                )
                        )

                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.isSaving)
            }
        }
        .scrollContentBackground(.hidden)
        .tint(AppColors.primary)
        .scrollDismissesKeyboard(.interactively)
    }

    private func saveActivity(
        _ model: ActivityFormViewModel
    ) async {

        guard !model.isSaving else {
            return
        }

        // Combine the selected date with the chosen times.
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
            guard let trip = try await
                tripRepository.fetchCurrentTrip()
            else {
                loadError = "Please create a trip first."
                return
            }

            if let existingActivity,
               existingActivity.tripId != trip.id {
                loadError = "This activity belongs to another trip."
                return
            }

            viewModel = ActivityFormViewModel(
                tripId: trip.id,
                repository: activityRepository,
                existingActivity: existingActivity
            )

            // Use the trip start date only for new activities.
            // Keep the original date when editing.
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
