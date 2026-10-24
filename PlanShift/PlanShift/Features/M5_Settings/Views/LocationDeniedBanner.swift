import SwiftUI

/// M5-05. Safe to embed in Settings: hidden when access is not blocked.
@MainActor
struct LocationDeniedBanner: View {
    @State private var model: LocationPermissionViewModel

    init() {
        self.init(location: CoreLocationService.shared)
    }

    init(location: any LocationProviding) {
        _model = State(initialValue: LocationPermissionViewModel(location: location))
    }

    init(model: LocationPermissionViewModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        if model.status.isBlocked {
            VStack(alignment: .leading, spacing: 12) {
                Label(model.status == .servicesDisabled ? "Location Services are off" : "Location access is off",
                      systemImage: "location.slash")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Text(explanation)
                Text("You can still manage your itinerary and use your planned activity’s location for recommendations.")
                    .font(.subheadline)
                Button { Task { await model.openSettings() } } label: {
                    Text("Open Settings")
                        .frame(minWidth: 44, minHeight: 44)
                }
                .buttonStyle(.bordered)
                .accessibilityHint("Opens PlanShift in the Settings app")
                if let message = model.settingsError {
                    Text(message).font(.footnote)
                }
            }
            .foregroundStyle(AppColors.textPrimary)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    private var explanation: String {
        switch model.status {
        case .servicesDisabled:
            "Location Services are off for this device. Open Settings, return to the main Settings screen, then go to Privacy & Security > Location Services to turn them on."
        case .restricted:
            "Location access is restricted on this device. You may need help from the person who manages its restrictions."
        default:
            "You can allow location access in Settings to find alternatives near you."
        }
    }
}

#if DEBUG
#Preview {
    LocationDeniedBanner(location: LocationPreviewService(status: .denied))
        .padding()
}

#Preview("Location Services off") {
    LocationDeniedBanner(location: LocationPreviewService(status: .servicesDisabled))
        .padding()
}
#endif
