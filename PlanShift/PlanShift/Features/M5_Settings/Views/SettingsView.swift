// Module: M3 – M5-06 Settings.

import SwiftUI

@MainActor
struct SettingsView: View {
    @State private var locationModel: LocationPermissionViewModel
        private let location: any LocationProviding

        init() {
            self.init(location: CoreLocationService.shared)
        }

        init(location: any LocationProviding) {
            self.location = location
            _locationModel = State(
                initialValue: LocationPermissionViewModel(location: location)
            )
        }
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                settingsSection("LOCATION") {
                    NavigationLink {
                        LocationPrePromptView(location: location)
                    } label: {
                        settingsRow(
                            "Location access",
                            icon: "location",
                            color: AppColors.primary,
                            value: locationStatusTitle,
                            showsBadge: true
                        )
                    }
                    .buttonStyle(.plain)
                } footer: {
                    Text("Used to rank alternatives near you.")
                }

                settingsSection("DEFAULT PREFERENCES") {
                    VStack(spacing: 0) {
                        settingsRow(
                            "Budget",
                            icon: "dollarsign.circle",
                            color: AppColors.delay,
                            value: BudgetOption.under30.title
                        )

                        Divider()

                        settingsRow(
                            "Indoor / outdoor",
                            icon: "umbrella",
                            color: AppColors.outOfTime,
                            value: SettingPreference.any.title
                        )

                        Divider()

                        settingsRow(
                            "Max distance",
                            icon: "figure.walk",
                            color: AppColors.rainy,
                            value: DistanceOption.threeKm.title
                        )
                    }
                }

                settingsSection("APPEARANCE") {
                    settingsRow(
                        "Appearance",
                        icon: "moon",
                        color: AppColors.outOfTime,
                        value: "Automatic"
                    )
                }

                settingsSection("ABOUT") {
                    VStack(spacing: 0) {
                        settingsRow(
                            "Privacy Policy",
                            icon: "shield",
                            color: AppColors.textSecondary
                        )

                        Divider()

                        settingsRow(
                            "About PlanShift",
                            icon: "arrow.left.arrow.right",
                            color: AppColors.primary,
                            value: "Version \(appVersion)",
                            showsChevron: false
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .foregroundStyle(AppColors.textPrimary)
        .background(AppColors.backgroundGradient.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .accessibilityIdentifier("M5-06")
    }
    
    private var locationStatusTitle: String {
        switch locationModel.status {
        case .notDetermined:
            "Not set"
        case .denied:
            "Denied"
        case .restricted:
            "Restricted"
        case .servicesDisabled:
            "Services off"
        case .authorizedWhenInUse:
            "While Using"
        }
    }

    private var appVersion: String {
        Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "0.1"
    }

    private func settingsSection<Content: View, Footer: View>(
        _ title: String,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.textSecondary)
                .padding(.horizontal, 8)
                .accessibilityAddTraits(.isHeader)

            content()
                .background(
                    .regularMaterial,
                    in: RoundedRectangle(cornerRadius: 20)
                )

            footer()
                .font(.caption)
                .foregroundStyle(AppColors.textSecondary)
                .padding(.horizontal, 8)
        }
    }

    private func settingsSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        settingsSection(title, content: content) {
            EmptyView()
        }
    }

    private func settingsRow(
        _ title: String,
        icon: String,
        color: Color,
        value: String? = nil,
        showsBadge: Bool = false,
        showsChevron: Bool = true
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(
                    color,
                    in: RoundedRectangle(cornerRadius: 10)
                )
                .accessibilityHidden(true)

            Text(title)
                .font(.body)

            Spacer(minLength: 8)

            if let value {
                if showsBadge {
                    Text(value)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppColors.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            AppColors.primary.opacity(0.12),
                            in: Capsule()
                        )
                } else {
                    Text(value)
                        .font(.body)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.trailing)
                }
            }

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(minHeight: 44)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        SettingsView(
            location: LocationPreviewService(
                status: .authorizedWhenInUse
            )
        )
    }
}
