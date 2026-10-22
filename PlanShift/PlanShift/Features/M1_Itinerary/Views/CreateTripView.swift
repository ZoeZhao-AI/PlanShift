
import SwiftUI

// Module: M1 - Create Trip

@MainActor
struct CreateTripView: View {

    @Environment(AppRouter.self) private var router
    @State private var viewModel: CreateTripViewModel
    @FocusState private var nameIsFocused: Bool

    private let isInMemoryMode: Bool

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

        let calendar = Calendar.current
        let dayDifference = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: viewModel.startDate),
            to: calendar.startOfDay(for: viewModel.endDate)
        ).day ?? 0
        let days = max(1, dayDifference + 1)
        let nights = max(0, days - 1)

        Form {
            Section {
                TextField("Trip name (e.g. Sydney Trip)", text: $viewModel.name)
                    .textInputAutocapitalization(.words)
                    .focused($nameIsFocused)
                    .frame(minHeight: 44)
            }

            Section {
                DatePicker("Start date", selection: $viewModel.startDate, displayedComponents: .date)
                DatePicker(
                    "End date",
                    selection: $viewModel.endDate,
                    in: viewModel.startDate...,
                    displayedComponents: .date
                )
            } footer: {
                Text("\(days) \(days == 1 ? "day" : "days") · \(nights) \(nights == 1 ? "night" : "nights")")
            }

            if let errorMessage = viewModel.errorMessage {
                Section {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }
            }

            if isInMemoryMode {
                Section {
                    Text("Development mode: trips are stored in memory.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .m1ScreenBackground()
        .navigationTitle("New Trip")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    if !router.itineraryPath.isEmpty {
                        router.itineraryPath.removeLast()
                    }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                if viewModel.isSaving {
                    ProgressView()
                } else {
                    Button("Create") { create() }
                }
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { nameIsFocused = false }
            }
        }
        .onChange(of: viewModel.startDate) { _, newDate in
            if viewModel.endDate < newDate {
                viewModel.endDate = newDate
            }
        }
    }

    private func create() {
        nameIsFocused = false
        Task {
            guard !viewModel.isSaving else { return }
            if await viewModel.createTrip() {
                router.itineraryPath = []
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
