// Module: M5 – placeholder for M5-04 Location Pre-prompt.

import SwiftUI

/// M5-04 Location Pre-prompt. Placeholder: the M5 owner replaces this with the real screen.
struct LocationPrePromptView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("M5-04").font(.largeTitle.bold())
            Text("Location Pre-prompt").font(.title2)
            Button("Allow Location") { dismiss() }
            Button("Not Now") { dismiss() }
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .foregroundStyle(AppColors.textPrimary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.backgroundGradient)
    }
}

#Preview {
    LocationPrePromptView()
}
