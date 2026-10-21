// Module: M1 – placeholder for M1-06 Create Trip.

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

        Form {
            Section("Trip details") {
                TextField(
                    "Trip name",
                    text: $viewModel.name
                )
                .textInputAutocapitalization(.words)
                .submitLabel(.done)
                .focused($nameIsFocused)
                .onSubmit {
                    nameIsFocused = false
                }
            }

            Section("Travel dates") {
                DatePicker(
                    "Start date",
                    selection: $viewModel.startDate,
                    displayedComponents: [.date]
                )

                DatePicker(
                    "End date",
                    selection: $viewModel.endDate,
                    displayedComponents: [.date]
                )
            }

            if let errorMessage = viewModel.errorMessage {
                Section {
                    Label(
                        errorMessage,
                        systemImage: "exclamationmark.circle"
                    )
                    .foregroundStyle(AppColors.textPrimary)
                }
            }

            Section {
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
                        }

                        Text(
                            viewModel.isSaving
                                ? "Creating..."
                                : "Create Trip"
                        )
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
            }

            if isInMemoryMode {
                Section {
                    Text(
                        "Development mode: trips are stored in memory only "
                        + "and are cleared when the app restarts."
                    )
                    .font(.footnote)
                }
            }
        }
        .disabled(viewModel.isSaving)
        .navigationTitle("Create Trip")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(AppColors.backgroundGradient)
        .tint(AppColors.primary)
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()

                Button("Done") {
                    nameIsFocused = false
                }
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
