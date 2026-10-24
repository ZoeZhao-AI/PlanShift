import Observation
import SwiftUI

/// M5-04. Uses the explanation already established by the M2 flow.
@MainActor
struct LocationPrePromptView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model: LocationPermissionViewModel
    @State private var requestsPermission = false

    init() {
        self.init(location: CoreLocationService.shared)
    }

    init(location: any LocationProviding) {
        _model = State(initialValue: LocationPermissionViewModel(location: location))
    }

    var body: some View {
        Group {
            if model.status == .notDetermined {
                LocationPermissionPromptView(
                    onAllow: { requestsPermission = true },
                    onNotNow: { dismiss() }
                )
                .disabled(model.isRequesting)
                .overlay {
                    if model.isRequesting {
                        ProgressView("Waiting for your choice…")
                            .padding()
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        if model.status.isAuthorized {
                            Label("Location access is enabled", systemImage: "location.circle")
                                .font(.title2)
                                .accessibilityAddTraits(.isHeader)
                            Text("PlanShift can use your location to find nearby alternatives while you use the app.")
                        } else {
                            LocationDeniedBanner(model: model)
                        }
                        Button { dismiss() } label: {
                            Text(model.status.isAuthorized ? "Done" : "Continue without location")
                                .frame(minWidth: 44, minHeight: 44)
                        }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                    }
                    .padding()
                }
                .background(AppColors.backgroundGradient)
            }
        }
        .navigationTitle("Location access")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: requestsPermission) {
            guard requestsPermission else { return }
            await model.allowLocation()
            requestsPermission = false
            if model.status.isAuthorized { dismiss() }
        }
        .onChange(of: model.status) { _, _ in model.refresh() }
    }
}

#if DEBUG
@MainActor
@Observable
final class LocationPreviewService: LocationProviding {
    nonisolated deinit {}

    var authorizationStatus: LocationAuthorizationStatus

    init(status: LocationAuthorizationStatus = .notDetermined) {
        authorizationStatus = status
    }

    func requestWhenInUseAuthorization() async -> LocationAuthorizationStatus {
        authorizationStatus = .denied
        return authorizationStatus
    }

    func currentLocation() async -> GeoCoordinate? { nil }
}
#Preview("Not requested") {
    NavigationStack { LocationPrePromptView(location: LocationPreviewService()) }
}

#Preview("Denied · Dark · Large text") {
    NavigationStack { LocationPrePromptView(location: LocationPreviewService(status: .denied)) }
        .preferredColorScheme(.dark)
        .environment(\.dynamicTypeSize, .accessibility5)
}
#endif
