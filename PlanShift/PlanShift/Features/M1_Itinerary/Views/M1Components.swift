// Module: M1 – shared building blocks for the Itinerary screens.

import SwiftUI
import UIKit

/// Finds the bundled photo for an activity's location.
/// Activities store a free-text location, so we match its slug ("Bondi Beach" → "bondi-beach")
/// against the asset catalog, then fall back to the activity name.
enum M1PlaceImage {
    static func name(for activity: ItineraryActivity) -> String? {
        [activity.locationName, activity.name]
            .map(M2Formatting.imageSlug(for:))
            .first { !$0.isEmpty && UIImage(named: $0) != nil }
    }
}

/// Location photo with a vector stand-in when no photo is bundled. Decorative.
struct ActivityPhotoView: View {
    let activity: ItineraryActivity

    var body: some View {
        PlaceArtworkView(
            name: activity.locationName,
            setting: activity.setting,
            imageName: M1PlaceImage.name(for: activity)
        )
    }
}

/// Indoor / Outdoor pill that uses the shared design tokens (readable in Light and Dark).
struct SettingPill: View {
    let setting: ActivitySetting

    var body: some View {
        let isIndoor = setting == .indoor
        Text(setting.title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(isIndoor ? AppColors.indoorForeground : AppColors.outdoorForeground)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(isIndoor ? AppColors.indoorBackground : AppColors.outdoorBackground, in: Capsule())
    }
}

extension View {
    /// Standard M1 screen background (follows Light / Dark).
    func m1ScreenBackground() -> some View {
        background(AppColors.backgroundGradient.ignoresSafeArea())
    }

    /// Grouped card surface that adapts to Light / Dark.
    func m1Card(cornerRadius: CGFloat = 16) -> some View {
        background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}
