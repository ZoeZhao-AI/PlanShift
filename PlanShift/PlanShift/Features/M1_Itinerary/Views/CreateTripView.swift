
import SwiftUI

// Module: M1 - Create Trip

@MainActor
struct CreateTripView: View {

    @Environment(AppRouter.self) private var router
    @State private var viewModel: CreateTripViewModel
    @FocusState private var nameIsFocused: Bool

    private let isInMemoryMode: Bool

    private let primaryGreen = Color(
        red: 0.02,
        green: 0.49,
        blue: 0.43
    )

    init(
        repository: any TripRepository =
            M1InMemoryTripRepository.shared
    ) {
        _viewModel = State(
            initialValue: CreateTripViewModel(
                createTripUseCase: CreateTripUseCase(
                    repository: repository
                )
            )
        )

        isInMemoryMode = repository is M1InMemoryTripRepository
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        VStack(spacing: 0) {

            // Header
            HStack {
                Button("Cancel") {
                    if !router.itineraryPath.isEmpty {
                        router.itineraryPath.removeLast()
                    }
                }
                .foregroundStyle(primaryGreen)

                Spacer()

                Text("New Trip")
                    .font(.headline)

                Spacer()

                Text("Cancel")
                    .hidden()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)

            ScrollView {
                VStack(spacing: 12) {

                    // Trip name
                    HStack {
                        Text("Trip name")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        TextField(
                            "Sydney Trip",
                            text: $viewModel.name
                        )
                        .multilineTextAlignment(.trailing)
                        .textInputAutocapitalization(.words)
                        .focused($nameIsFocused)
                    }
                    .padding(15)
                    .background(
                        .white,
                        in: RoundedRectangle(cornerRadius: 15)
                    )

                    // Start and end dates
                    VStack(spacing: 0) {

                        DatePicker(
                            "Start date",
                            selection: $viewModel.startDate,
                            displayedComponents: .date
                        )
                        .padding(12)

                        Divider()

                        DatePicker(
                            "End date",
                            selection: $viewModel.endDate,
                            in: viewModel.startDate...,
                            displayedComponents: .date
                        )
                        .padding(12)
                    }
                    .background(
                        .white,
                        in: RoundedRectangle(cornerRadius: 15)
                    )

                    // Calendar
                    DatePicker(
                        "Choose dates",
                        selection: $viewModel.startDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .tint(primaryGreen)
                    .padding(10)
                    .background(
                        .white,
                        in: RoundedRectangle(cornerRadius: 16)
                    )

                    // Trip duration
                    let dayDifference = Calendar.current.dateComponents(
                        [.day],
                        from: Calendar.current.startOfDay(
                            for: viewModel.startDate
                        ),
                        to: Calendar.current.startOfDay(
                            for: viewModel.endDate
                        )
                    ).day ?? 0

                    let days = max(1, dayDifference + 1)
                    let nights = max(0, days - 1)

                    Text(
                        "\(days) \(days == 1 ? "day" : "days") · " +
                        "\(nights) \(nights == 1 ? "night" : "nights")"
                    )
                    .font(.caption.bold())
                    .foregroundStyle(primaryGreen)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        primaryGreen.opacity(0.08),
                        in: Capsule()
                    )

                    if let errorMessage = viewModel.errorMessage {
                        Label(
                            errorMessage,
                            systemImage: "exclamationmark.triangle"
                        )
                        .font(.footnote)
                        .foregroundStyle(.red)
                    }

                    if isInMemoryMode {
                        Text(
                            "Development mode: trips are stored in memory."
                        )
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .scrollDismissesKeyboard(.interactively)

            // Bottom button
            Button {
                nameIsFocused = false

                Task {
                    guard !viewModel.isSaving else {
                        return
                    }

                    let succeeded = await viewModel.createTrip()

                    if succeeded {
                        router.itineraryPath = []
                    }
                }
            } label: {
                HStack {
                    if viewModel.isSaving {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "checkmark")
                    }

                    Text(
                        viewModel.isSaving
                            ? "Creating..."
                            : "Create trip"
                    )
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .foregroundStyle(.white)
                .background(
                    primaryGreen,
                    in: RoundedRectangle(cornerRadius: 12)
                )
            }
            .disabled(viewModel.isSaving)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
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
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()

                Button("Done") {
                    nameIsFocused = false
                }
            }
        }
        .onChange(of: viewModel.startDate) {
            _, newDate in

            if viewModel.endDate < newDate {
                viewModel.endDate = newDate
            }
        }
    }
}

#Preview {
    NavigationStack {
        CreateTripView(
            repository: M1InMemoryTripRepository()
        )
    }
    .environment(AppRouter())
}
