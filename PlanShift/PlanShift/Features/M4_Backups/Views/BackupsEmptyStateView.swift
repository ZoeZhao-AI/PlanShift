// Module: M4 – placeholder for M4-03 Empty State.

import SwiftUI

/// M4-03 Empty State. Placeholder: the M4 owner replaces this with the real screen.
struct BackupsEmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("M4-03").font(.largeTitle.bold())
            Text("Empty State").font(.title2)
        }
        .foregroundStyle(AppColors.textPrimary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.backgroundGradient)
    }
}

#Preview {
    BackupsEmptyStateView()
}
