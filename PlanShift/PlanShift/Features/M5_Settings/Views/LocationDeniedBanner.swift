// Module: M5 – placeholder for M5-05 Location Denied Banner.

import SwiftUI

/// M5-05 Location Denied Banner (shown when location access is off).
/// Placeholder: the M5 owner replaces this with the real banner.
struct LocationDeniedBanner: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("M5-05").font(.largeTitle.bold())
            Text("Location Denied Banner").font(.title2)
        }
        .foregroundStyle(AppColors.textPrimary)
        .frame(maxWidth: .infinity)
        .padding()
        .background(.regularMaterial)
    }
}

#Preview {
    LocationDeniedBanner()
}
