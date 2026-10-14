// Module: M2 – placeholder for M2-04 No Results.

import SwiftUI

/// M2-04 No Results. Placeholder: the M2 owner replaces this with the real screen.
struct NoResultsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("M2-04").font(.largeTitle.bold())
            Text("No Results").font(.title2)
            Button("Adjust Filters") { dismiss() }
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .foregroundStyle(AppColors.textPrimary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.backgroundGradient)
    }
}

#Preview {
    NoResultsView()
}
