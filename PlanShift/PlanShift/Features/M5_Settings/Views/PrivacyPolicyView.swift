//
//  PrivacyPolicyView.swift
//  PlanShift
//
//  Created by Chang Chia ming on 2026/10/21.
//

// Module: M3 – privacy information for M5-06 Settings.

import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("How PlanShift uses your data")
                    .font(.title2.bold())
                    .accessibilityAddTraits(.isHeader)

                policySection(
                    "Your travel plans",
                    text: """
                    PlanShift stores your itinerary and saved backups \
                    locally on your device. This includes the activity \
                    names, dates, times and planned locations you save.
                    """
                )

                policySection(
                    "Location access",
                    text: """
                    With your permission, PlanShift requests your current \
                    location while you use the app to find nearby \
                    alternatives and estimate distances.

                    Your current device location is not saved by PlanShift. \
                    The app does not track your location in the background.
                    """
                )

                policySection(
                    "Your location choices",
                    text: """
                    You can use PlanShift without location access. \
                    Recommendations can use your planned activity's \
                    location instead.

                    You can review or change location access in the \
                    Settings app on your device.
                    """
                )

                policySection(
                    "Widget",
                    text: """
                    PlanShift and its widget share a local database \
                    through an App Group. This lets the widget display \
                    your next activity and saved backups on the Home Screen.
                    """
                )

                policySection(
                    "Preferences",
                    text: """
                    Your default budget, indoor or outdoor preference, \
                    distance preference and appearance choice are saved \
                    locally so they remain available when you reopen the app.
                    """
                )

                policySection(
                    "Managing your data",
                    text: """
                    You can remove activities and saved backups using \
                    the controls in the app. Location permission is \
                    managed separately in your device's Settings app.
                    """
                )
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(AppColors.textPrimary)
        .background(AppColors.backgroundGradient.ignoresSafeArea())
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func policySection(
        _ title: String,
        text: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            Text(text)
                .font(.body)
                .foregroundStyle(AppColors.textSecondary)
        }
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
