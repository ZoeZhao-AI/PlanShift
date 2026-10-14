// Module: M4 – placeholder for M4-04 Duplicate Toast.

import SwiftUI

/// M4-04 Duplicate Toast (shown when a place is already saved as a backup).
/// Placeholder: the M4 owner replaces this with the real toast.
struct DuplicateBackupToast: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("M4-04").font(.largeTitle.bold())
            Text("Duplicate Toast").font(.title2)
        }
        .foregroundStyle(AppColors.coral)
        .frame(maxWidth: .infinity)
        .padding()
        .background(.regularMaterial)
    }
}

#Preview {
    DuplicateBackupToast()
}
