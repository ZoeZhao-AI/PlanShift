// Module: M1 – placeholder for M1-02 Add/Edit Activity.

import SwiftUI

/// M1-02 Add/Edit Activity. Placeholder: the M1 owner replaces this with the real screen.
struct ActivityFormView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("M1-02").font(.largeTitle.bold())
            Text("Add/Edit Activity").font(.title2)
            Button("Save") { dismiss() }
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .foregroundStyle(AppColors.textPrimary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.backgroundGradient)
    }
}

#Preview {
    ActivityFormView()
}
