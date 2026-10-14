// Module: M5 – placeholder for M5-06 Settings.

import SwiftUI

/// M5-06 Settings. Placeholder: the M5 owner replaces this with the real screen.
struct SettingsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("M5-06").font(.largeTitle.bold())
            Text("Settings").font(.title2)
            NavigationLink("Location Pre-prompt") { LocationPrePromptView() }
            LocationDeniedBanner()
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .foregroundStyle(AppColors.textPrimary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.backgroundGradient)
    }
}

#Preview {
    NavigationStack { SettingsView() }
}
