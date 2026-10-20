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
                Label("Location access is off", systemImage: "location.slash")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Text(model.status == .restricted
                     ? "Location access is restricted on this device. You may need help from the person who manages its restrictions."
                     : "You can allow location access in Settings to find alternatives near you.")
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
}

#if DEBUG
#Preview {
    LocationDeniedBanner(location: LocationPreviewService(status: .denied))
        .padding()
}
#endif
